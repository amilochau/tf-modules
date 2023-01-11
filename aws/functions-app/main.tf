terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.44"
    }
  }

  required_version = ">= 1.3.0"
}

module "environment" {
  source      = "../../shared/environment"
  conventions = var.conventions
}

module "conventions" {
  source      = "../../shared/conventions"
  conventions = var.conventions
}

data "aws_region" "current" {}

data "aws_cognito_user_pools" "cognito_userpool" {
  name = module.conventions.aws_existing_conventions.cognito_userpool_name
}

locals {
  apigateway_authorizer_audience = values(aws_cognito_user_pool_client.cognito_userpool_client)[*].id
  apigateway_authorizer_issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${data.aws_cognito_user_pools.cognito_userpool.ids[0]}"
}

module "lambda" {
  source = "./lambda"

  conventions = var.conventions
  settings = var.lambda_settings
}

# ===== COGNITO CLIENT FOR API =====

#resource "aws_cognito_user_pool_client" "cognito_userpool_client_api" {
#  name         = module.conventions.aws_naming_conventions.cognito_userpool_client_api_name
#  user_pool_id = data.aws_cognito_user_pools.cognito_userpool.ids[0]
#  allowed_oauth_flows = [
#    "code"
#  ]
#  allowed_oauth_scopes = [
#    "email",
#    "openid"
#  ]
#  allowed_oauth_flows_user_pool_client = true
#  callback_urls = [
#    aws_apigatewayv2_stage.apigateway_stage.invoke_url
#  ]
#  explicit_auth_flows = [
#    "ALLOW_USER_PASSWORD_AUTH",
#    "ALLOW_REFRESH_TOKEN_AUTH"
#  ]
#  supported_identity_providers = ["COGNITO"]
#}

# ===== API GATEWAY =====

resource "aws_apigatewayv2_api" "apigateway_api" {
  name             = module.conventions.aws_naming_conventions.apigateway_api_name
  protocol_type    = "HTTP"
}

resource "aws_apigatewayv2_stage" "apigateway_stage" {
  name        = module.conventions.aws_naming_conventions.apigateway_stage_name
  api_id      = aws_apigatewayv2_api.apigateway_api.id
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.cloudwatch_loggroup_apigateway.arn
    format          = module.conventions.aws_format_conventions.apigateway_accesslog_format
  }
}

resource "aws_apigatewayv2_integration" "apigateway_integration" {
  api_id                 = aws_apigatewayv2_api.apigateway_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = module.lambda.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "apigateway_authorizer" {
  name             = module.conventions.aws_naming_conventions.apigateway_authorizer_name
  api_id           = aws_apigatewayv2_api.apigateway_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = local.apigateway_authorizer_audience
    issuer   = local.apigateway_authorizer_issuer
  }
}

resource "aws_apigatewayv2_route" "apigateway_route_cors" {
  api_id    = aws_apigatewayv2_api.apigateway_api.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.apigateway_integration.id}"
}

resource "aws_apigatewayv2_route" "apigateway_route_default" {
  api_id               = aws_apigatewayv2_api.apigateway_api.id
  route_key            = "ANY /{proxy+}"
  target               = "integrations/${aws_apigatewayv2_integration.apigateway_integration.id}"
  authorizer_id        = aws_apigatewayv2_authorizer.apigateway_authorizer.id
  authorization_type   = "JWT"
  authorization_scopes = []
}

resource "aws_lambda_permission" "apigateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigateway_api.execution_arn}/*/*"
}

# ===== API GATEWAY LOGGING =====

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_apigateway" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.apigateway_api.name}/${module.conventions.aws_naming_conventions.apigateway_stage_name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
}

# ===== COGNITO CLIENTS =====

resource "aws_cognito_user_pool_client" "cognito_userpool_client" {
  for_each = var.clients
  name     = each.key

  user_pool_id                  = data.aws_cognito_user_pools.cognito_userpool.ids[0]
  generate_secret               = false
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}
