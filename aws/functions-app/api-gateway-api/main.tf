terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.37, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.7.3, < 2.0.0"
}

module "conventions" {
  source  = "../../../shared/conventions"
  context = var.context
}

data "aws_region" "current" {
  provider = aws.workloads
}

locals {
  apigateway_authorizer_audience = var.cognito_settings.client_ids
  apigateway_authorizer_issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_settings.user_pool_id}"
}

resource "aws_apigatewayv2_api" "apigateway_api" {
  name          = module.conventions.aws_naming_conventions.apigateway_api_name
  protocol_type = "HTTP"

  provider = aws.workloads
}

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_apigateway" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.apigateway_api.name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days

  provider = aws.workloads
}

resource "aws_apigatewayv2_stage" "apigateway_stage" {
  name        = "$default"
  api_id      = aws_apigatewayv2_api.apigateway_api.id
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = module.conventions.aws_format_conventions.apigateway_throttling_burst_limit
    throttling_rate_limit  = module.conventions.aws_format_conventions.apigateway_throttling_rate_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.cloudwatch_loggroup_apigateway.arn
    format          = module.conventions.aws_format_conventions.apigateway_accesslog_format
  }

  provider = aws.workloads
}

resource "aws_apigatewayv2_authorizer" "apigateway_authorizer" {
  count            = var.enable_authorizer ? 1 : 0
  name             = module.conventions.aws_naming_conventions.apigateway_authorizer_name
  api_id           = aws_apigatewayv2_api.apigateway_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = local.apigateway_authorizer_audience
    issuer   = local.apigateway_authorizer_issuer
  }

  provider = aws.workloads
}
