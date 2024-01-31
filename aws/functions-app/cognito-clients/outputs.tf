output "cognito_client_ids" {
  description = "Ids of the created Cognito clients"
  value       = concat(values(aws_cognito_user_pool_client.cognito_userpool_client_temporary)[*].id, values(aws_cognito_user_pool_client.cognito_userpool_client)[*].id)
}
