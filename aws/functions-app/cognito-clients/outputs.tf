output "cognito_user_pool_id" {
  description = "Id of the Cognito user pool"
  value       = local.cognito_user_pool_id
}

output "cognito_client_ids" {
  description = "Ids of the created Cognito clients"
  value       = values(aws_cognito_user_pool_client.cognito_userpool_client2)[*].id
}
