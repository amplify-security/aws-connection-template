resource "aws_iam_role" "this" {
  name_prefix          = "AmplifyConsoleAccess-"
  description          = "Assumed by Amplify Console's agents to use this account through the AWS MCP Server, with the permissions of the attached managed policies."
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::791657206107:root" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = { "sts:ExternalId" = var.external_id }
          ArnEquals    = { "aws:PrincipalArn" = var.amplify_connector_role_arn }
          StringLike   = { "sts:RoleSessionName" = "amplify-*" }
        }
      },
      # Its own statement: like sts:TagSession, sts:SetSourceIdentity may not match a statement that conditions on
      # sts:ExternalId, which would refuse every AssumeRole call that sets a source identity.
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::791657206107:root" }
        Action    = "sts:SetSourceIdentity"
        Condition = { ArnEquals = { "aws:PrincipalArn" = var.amplify_connector_role_arn } }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "this" {
  role_name   = aws_iam_role.this.name
  policy_arns = var.managed_policy_arns
}

resource "aws_iam_role_policy" "this" {
  name = "AmplifyConsoleMcp"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NoCredentialOrSecretReadsThroughMcp"
        Effect = "Deny"
        Action = [
          "sts:GetSessionToken",
          "sts:GetFederationToken",
          "ecr:GetAuthorizationToken",
          "ecr-public:GetAuthorizationToken",
          "codeartifact:GetAuthorizationToken",
          "redshift:GetClusterCredentials*",
          "redshift-serverless:GetCredentials",
          "ec2:GetPasswordData",
          "lightsail:GetInstanceAccessDetails",
          "lightsail:GetRelationalDatabaseMasterUserPassword",
          "rds-db:connect",
          "secretsmanager:GetSecretValue",
          "secretsmanager:BatchGetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:GetParameterHistory",
          "glue:GetConnection",
          "glue:GetConnections",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "kms:Decrypt",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
        ]
        Resource  = "*"
        Condition = { Bool = { "aws:ViaAWSMCPService" = "true" } }
      },
      # A presigned URL is redeemed directly against S3, outside the AWS MCP Server, so this deny is unconditional.
      {
        Sid       = "NoPresignedS3Downloads"
        Effect    = "Deny"
        Action    = "s3:GetObject*"
        Resource  = "*"
        Condition = { StringEquals = { "s3:authType" = "REST-QUERY-STRING" } }
      },
    ]
  })
}
