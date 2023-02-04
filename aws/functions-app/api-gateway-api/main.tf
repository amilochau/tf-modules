module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

data "aws_region" "current" {}

locals {
  apigateway_authorizer_audience = var.cognito_settings.client_ids
  apigateway_authorizer_issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_settings.user_pool_id}"
}

resource "aws_apigatewayv2_api" "apigateway_api" {
  name          = module.conventions.aws_naming_conventions.apigateway_api_name
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_apigateway" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.apigateway_api.name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
}

resource "aws_apigatewayv2_stage" "apigateway_stage" {
  name        = "$default"
  api_id      = aws_apigatewayv2_api.apigateway_api.id
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.cloudwatch_loggroup_apigateway.arn
    format          = module.conventions.aws_format_conventions.apigateway_accesslog_format
  }
}

resource "aws_apigatewayv2_authorizer" "apigateway_authorizer" {
  count            = var.enable_authorizer ? 1 : 0
  name             = module.conventions.aws_naming_conventions.apigateway_authorizer_name
  api_id           = aws_apigatewayv2_api.apigateway_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  authorizer_payload_format_version = "2.0"

  jwt_configuration {
    audience = local.apigateway_authorizer_audience
    issuer   = local.apigateway_authorizer_issuer
  }
}
