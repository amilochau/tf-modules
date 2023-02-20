output "apigateway_invoke_domain" {
  description = "Invoke URL of the default API Gateway stage"
  value       = regex(module.conventions.aws_format_conventions.urlparse_regex, module.api_gateway_api.apigateway_invoke_url).authority
}

output "apigateway_invoke_origin_path" {
  description = "Invoke URL of the default API Gateway stage"
  value       = local.has_http_triggers ? "/${module.api_gateway_api[0].apigateway_stage_name}" : ""
}
