output "apigateway_invoke_url" {
  description = "Invoke URL of the default API Gateway stage"
  value       = local.has_http_triggers ? module.api_gateway_api[0].apigateway_invoke_url : ""
}

output "apigateway_invoke_domain" {
  description = "Invoke domain of the default API Gateway stage"
  value       = local.has_http_triggers ? module.api_gateway_api[0].apigateway_invoke_domain : ""
}

output "apigateway_invoke_origin_path" {
  description = "Invoke URL of the default API Gateway stage"
  value       = local.has_http_triggers ? (module.api_gateway_api[0].apigateway_stage_name != "$default" ? "/${module.api_gateway_api[0].apigateway_stage_name}" : "") : ""
}
