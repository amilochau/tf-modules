output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.dynamodb_table.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.dynamodb_table.arn
}

output "stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = aws_dynamodb_table.dynamodb_table.stream_arn
}
