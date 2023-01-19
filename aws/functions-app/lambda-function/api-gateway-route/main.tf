resource "aws_apigatewayv2_integration" "apigateway_integration" {
  api_id                 = var.apigateway_settings.api_id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.function_settings.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "apigateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.function_settings.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.apigateway_settings.api_execution_arn}/*/*" # Allow invocation from any stage, any method, any resource path @todo restrict that?
}

resource "aws_apigatewayv2_route" "apigateway_route_cors" {
  count     = var.function_settings.enable_cors ? 1 : 0
  api_id    = var.apigateway_settings.api_id
  route_key = "OPTIONS ${var.function_settings.route}"
  target    = "integrations/${aws_apigatewayv2_integration.apigateway_integration.id}"
}

resource "aws_apigatewayv2_route" "apigateway_route_default" {
  api_id    = var.apigateway_settings.api_id
  route_key = "${var.function_settings.method} ${var.function_settings.route}"
  target    = "integrations/${aws_apigatewayv2_integration.apigateway_integration.id}"

  authorizer_id        = var.function_settings.anonymous ? null : var.apigateway_settings.authorizer_id
  authorization_type   = var.function_settings.anonymous ? null : "JWT"
  authorization_scopes = []
}
