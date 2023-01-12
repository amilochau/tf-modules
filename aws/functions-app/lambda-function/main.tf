module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

data "aws_iam_policy_document" "lambda_logging_policy_document" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*" # @todo check if the 'resource' is not too large (we want to have something like "arn:aws:logs:eu-west-3:266302224431:log-group:/aws/lambda/todelete-lambda-function:*")
    ]
    effect = "Allow"
  }
}

# ===== LAMBDA =====

resource "aws_lambda_function" "lambda_function" {
  function_name = "${module.conventions.aws_naming_conventions.lambda_function_name_prefix}-${var.settings.function_key}"
  role          = var.iam_role_settings.arn

  filename         = var.settings.deployment_file_path
  source_code_hash = filebase64sha256(var.settings.deployment_file_path)
  runtime          = var.settings.runtime
  architectures    = [var.settings.architecture]
  timeout          = var.settings.timeout_s
  memory_size      = var.settings.memory_size_mb
  handler          = var.settings.handler
}

# ===== LAMBDA LOGGING =====

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
}

resource "aws_iam_policy" "lambda_logging_role" {
  name        = "${module.conventions.aws_naming_conventions.lambda_logging_policy_name_prefix}-${var.settings.function_key}"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = var.iam_role_settings.name
  policy_arn = aws_iam_policy.lambda_logging_role.arn
}

# ===== API GATEWAY ROUTE =====

module "api_gateway_route" {
  count  = var.settings.http_trigger != null ? 1 : 0
  source = "../api-gateway-route"

  route_settings = {
    function_name = aws_lambda_function.lambda_function.function_name
    invoke_arn    = aws_lambda_function.lambda_function.invoke_arn
    method        = var.settings.http_trigger.method
    route         = var.settings.http_trigger.route
    anonymous     = var.settings.http_trigger.anonymous
    enable_cors   = var.settings.http_trigger.enable_cors
  }
  apigateway_settings = {
    api_id            = var.apigateway_settings.api_id
    api_execution_arn = var.apigateway_settings.api_execution_arn
    authorizer_id     = var.apigateway_settings.authorizer_id
  }
}
