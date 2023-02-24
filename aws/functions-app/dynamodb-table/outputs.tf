output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.dynamodb_table.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.dynamodb_table.arn
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy to workk with DynamoDB table"
  value       = aws_iam_policy.lambda_iam_policy_dynamodb.arn
}
