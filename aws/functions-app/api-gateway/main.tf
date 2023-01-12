module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

data "aws_region" "current" {}

locals {
  apigateway_authorizer_audience = var.cognito_outputs.client_ids
  apigateway_authorizer_issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_outputs.user_pool_id}"
}

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
  integration_uri        = var.functions_outputs.invoke_arn
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
  function_name = var.functions_outputs.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigateway_api.execution_arn}/*/*"
}

# ===== API GATEWAY LOGGING =====

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_apigateway" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.apigateway_api.name}/${module.conventions.aws_naming_conventions.apigateway_stage_name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
}
