output "iam_policy_arn" {
  description = "ARN of the IAM policy to work with SES identity"
  value       = aws_iam_policy.lambda_iam_policy_ses.arn
}
