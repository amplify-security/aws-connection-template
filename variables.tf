variable "amplify_connector_role_arn" {
  type        = string
  description = "Amplify's connector role, which assumes this role. Leave the default."
  default     = "arn:aws:iam::791657206107:role/amplify-console-prod-aws-connector"
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws:iam::791657206107:role/amplify-console-(lab|stg|prod)-aws-connector$", var.amplify_connector_role_arn))
    error_message = "amplify_connector_role_arn must be an Amplify connector role ARN."
  }
}

variable "external_id" {
  type        = string
  description = "The external ID Amplify Console issued for this connection."

  validation {
    condition     = can(regex("^[0-9a-f]{64}$", var.external_id))
    error_message = "external_id must be 64 lowercase hexadecimal characters."
  }
}

variable "managed_policy_arns" {
  type        = list(string)
  description = "Managed policies that set what Amplify's agents can do through the AWS MCP Server, writes included. The module only refuses credential, secret and data reads through the MCP Server, and presigned S3 downloads. The defaults, SecurityAudit and CloudWatchLogsReadOnlyAccess, give read access, including to configuration and log events that often hold secrets, such as environment variables, EC2 user data and CloudFormation templates."
  default     = ["arn:aws:iam::aws:policy/SecurityAudit", "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"]
  nullable    = false
}
