# The module must create the same role as AmplifyConsoleAccess.yaml.

mock_provider "aws" {}

variables {
  external_id = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

  # Not a module input: the template with its parameter Refs substituted by the external ID above and the
  # template's default connector role, which the module's default must match.
  template = jsondecode(replace(replace(
    jsonencode(yamldecode(file("AmplifyConsoleAccess.yaml"))),
    jsonencode({ Ref = "ExternalId" }), jsonencode("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")),
    jsonencode({ Ref = "AmplifyConnectorRoleArn" }), jsonencode(yamldecode(file("AmplifyConsoleAccess.yaml")).Parameters.AmplifyConnectorRoleArn.Default)
  ))
}

run "matches_template" {
  command = plan

  assert {
    condition     = keys(var.template.Resources) == ["AmplifyConsoleAccessRole"]
    error_message = "The template must create only AmplifyConsoleAccessRole."
  }

  assert {
    condition     = keys(var.template.Resources.AmplifyConsoleAccessRole.Properties) == ["AssumeRolePolicyDocument", "Description", "ManagedPolicyArns", "MaxSessionDuration", "Policies", "RoleName"]
    error_message = "The template's role has a property this test does not compare with the module."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this.assume_role_policy) == var.template.Resources.AmplifyConsoleAccessRole.Properties.AssumeRolePolicyDocument
    error_message = "The trust policy, or the default connector role, differs from the template's."
  }

  assert {
    condition     = [{ PolicyName = aws_iam_role_policy.this.name, PolicyDocument = jsondecode(aws_iam_role_policy.this.policy) }] == var.template.Resources.AmplifyConsoleAccessRole.Properties.Policies
    error_message = "The inline policy differs from the template's."
  }

  assert {
    condition     = toset(aws_iam_role_policy_attachments_exclusive.this.policy_arns) == toset(split(",", var.template.Parameters.ManagedPolicyArns.Default))
    error_message = "The default managed policies differ from the template's."
  }

  assert {
    condition     = aws_iam_role.this.description == var.template.Resources.AmplifyConsoleAccessRole.Properties.Description
    error_message = "The role description differs from the template's."
  }

  assert {
    condition     = aws_iam_role.this.max_session_duration == var.template.Resources.AmplifyConsoleAccessRole.Properties.MaxSessionDuration
    error_message = "The maximum session duration differs from the template's."
  }

  assert {
    condition     = "${aws_iam_role.this.name_prefix}$${Suffix}" == var.template.Resources.AmplifyConsoleAccessRole.Properties.RoleName["Fn::Sub"][0]
    error_message = "The role name prefix differs from the template's."
  }

  # The template sets none of these; a path also takes the role outside the connector's role/AmplifyConsoleAccess-* grant.
  assert {
    condition     = aws_iam_role.this.path == null && aws_iam_role.this.permissions_boundary == null && aws_iam_role.this.tags == null
    error_message = "The module's role sets a path, permissions boundary or tags that the template does not."
  }

  assert {
    condition = alltrue([
      can(regex(var.template.Parameters.AmplifyConnectorRoleArn.AllowedPattern, "arn:aws:iam::791657206107:role/amplify-console-lab-aws-connector")),
      !can(regex(var.template.Parameters.AmplifyConnectorRoleArn.AllowedPattern, "arn:aws:iam::123456789012:role/amplify-console-prod-aws-connector")),
      !can(regex(var.template.Parameters.AmplifyConnectorRoleArn.AllowedPattern, "arn:aws:iam::791657206107:role/amplify-console-prod-aws-connector-x")),
      can(regex(var.template.Parameters.ExternalId.AllowedPattern, "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")),
      !can(regex(var.template.Parameters.ExternalId.AllowedPattern, "0123456789ABCDEF0123456789abcdef0123456789abcdef0123456789abcdef")),
      !can(regex(var.template.Parameters.ExternalId.AllowedPattern, "0123456789abcdef")),
    ])
    error_message = "The template's AllowedPatterns no longer match the inputs rejects_what_the_template_rejects uses."
  }
}

# The same rejected inputs as the AllowedPattern assertion above.
run "rejects_what_the_template_rejects" {
  command = plan

  variables {
    amplify_connector_role_arn = "arn:aws:iam::123456789012:role/amplify-console-prod-aws-connector"
    external_id                = "0123456789ABCDEF0123456789abcdef0123456789abcdef0123456789abcdef"
  }

  expect_failures = [var.amplify_connector_role_arn, var.external_id]
}
