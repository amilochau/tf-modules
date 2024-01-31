output "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.cognito_user_pool.arn
}

output "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool"
  value       = aws_cognito_user_pool.cognito_user_pool.name
}

output "cognito_user_pool_id" {
  description = "Id of the Cognito User Pool"
  value       = aws_cognito_user_pool.cognito_user_pool.id
}
