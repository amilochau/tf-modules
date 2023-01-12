output "apigateway_api_id" {
  description = "Id of the API Gateway API"
  value       = aws_apigatewayv2_api.apigateway_api.id
}

output "apigateway_api_execution_arn" {
  description = "Execution ARN of the API Gateway API"
  value       = aws_apigatewayv2_api.apigateway_api.execution_arn
}

output "apigateway_authorizer_id" {
  description = "Id of the API Gateway authorizer"
  value       = var.enable_authorizer ? aws_apigatewayv2_authorizer.apigateway_authorizer[0].id : null
}
