module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

# ===== LAMBDA IAM ROLE =====

data "aws_iam_policy_document" "lambda_iam_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  name               = "${module.conventions.aws_naming_conventions.lambda_iam_role_name_prefix}-${var.settings.function_key}"
  description        = "IAM role used by the lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_policy_document.json
}

# ===== LAMBDA =====

resource "aws_lambda_function" "lambda_function" {
  function_name = "${module.conventions.aws_naming_conventions.lambda_function_name_prefix}-${var.settings.function_key}"
  role          = aws_iam_role.lambda_iam_role.arn

  filename         = var.settings.deployment_file_path
  source_code_hash = filebase64sha256(var.settings.deployment_file_path)
  runtime          = var.settings.runtime
  architectures    = [var.settings.architecture]
  timeout          = var.settings.timeout_s
  memory_size      = var.settings.memory_size_mb
  handler          = var.settings.handler

  environment {
    variables = {
      for k, v in var.dynamodb_settings : upper("DYNAMODB_TABLE__${k}") => v.table_name
    }
  }
}

# ===== LAMBDA LOGGING =====

data "aws_iam_policy_document" "lambda_iam_policy_document_logging" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.cloudwatch_loggroup_lambda.arn
    ]
    effect = "Allow"
  }
}

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
}

resource "aws_iam_policy" "lambda_iam_policy_logging" {
  name        = "${module.conventions.aws_naming_conventions.lambda_logging_policy_name_prefix}-${var.settings.function_key}"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_iam_policy_document_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachment_logging" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy_logging.arn
}

# ===== LAMBDA ACCESS TO DYNAMODB

data "aws_iam_policy_document" "lambda_iam_policy_document_dynamodb" {
  for_each = var.dynamodb_settings
  statement {
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      each.value.table_arn
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "lambda_iam_policy_dynamodb" {
  for_each = data.aws_iam_policy_document.lambda_iam_policy_document_dynamodb

  name = "${module.conventions.aws_naming_conventions.lambda_dynamodb_policy_name_prefix}-${each.key}-${var.settings.function_key}"
  description = "IAM policy for using a DynamoDB table from a lambda"
  policy      = each.value.json
}

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachment_dynamodb" {
  for_each = aws_iam_policy.lambda_iam_policy_dynamodb

  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = each.value.arn
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
