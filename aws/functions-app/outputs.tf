output "apigateway_invoke_domain" {
  description = "Invoke URL of the default API Gateway stage"
  value       = regex(module.conventions.aws_format_conventions.urlparse_regex, module.api_gateway_api.apigateway_invoke_url).authority
}

output "apigateway_invoke_origin_path" {
  description = "Invoke URL of the default API Gateway stage"
  value       = module.api_gateway_api.apigateway_stage_name
}
