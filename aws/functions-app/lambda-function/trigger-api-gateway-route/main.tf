terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.8.0, < 2.0.0"
}

resource "aws_apigatewayv2_integration" "apigateway_integration" {
  api_id                 = var.api_gateway_settings.api_id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.function_settings.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
  description            = var.api_gateway_settings.description

  provider = aws.workloads
}

resource "aws_apigatewayv2_route" "apigateway_route_cors" {
  count     = var.api_gateway_settings.enable_cors ? 1 : 0
  api_id    = var.api_gateway_settings.api_id
  route_key = "OPTIONS ${var.api_gateway_settings.route}"
  target    = "integrations/${aws_apigatewayv2_integration.apigateway_integration.id}"

  provider = aws.workloads
}

resource "aws_apigatewayv2_route" "apigateway_route_default" {
  api_id    = var.api_gateway_settings.api_id
  route_key = "${var.api_gateway_settings.method} ${var.api_gateway_settings.route}"
  target    = "integrations/${aws_apigatewayv2_integration.apigateway_integration.id}"

  authorizer_id        = var.api_gateway_settings.anonymous ? null : var.api_gateway_settings.authorizer_id
  authorization_type   = var.api_gateway_settings.anonymous ? null : "JWT"
  authorization_scopes = []

  provider = aws.workloads
}
