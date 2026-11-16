output "role_arn" {
  description = "ARN of the AmplifyConsoleAccess role."
  value       = aws_iam_role.this.arn
}
