output "iam_policy_arn" {
  description = "ARN of the IAM policy to use CloudWatch log group"
  value       = aws_iam_policy.iam_policy_cloudwatch_log_group.arn
}
