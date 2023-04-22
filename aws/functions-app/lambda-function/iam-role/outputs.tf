output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.lambda_iam_role.arn
}
