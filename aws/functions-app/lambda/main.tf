module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

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
  function_name = module.conventions.aws_naming_conventions.lambda_function_name
  role          = aws_iam_role.lambda_iam_role.arn

  filename         = var.settings.deployment_file_path
  source_code_hash = filebase64sha256(var.settings.deployment_file_path)
  runtime          = var.settings.runtime
  architectures    = [var.settings.architecture]
  timeout          = var.settings.timeout_s
  memory_size      = var.settings.memory_size_mb
  handler          = var.settings.handler
}

resource "aws_iam_role" "lambda_iam_role" {
  name               = module.conventions.aws_naming_conventions.lambda_iam_role_name
  description        = "IAM role used by the lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_policy_document.json
}

# ===== LAMBDA LOGGING =====

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
}

resource "aws_iam_policy" "lambda_logging_role" {
  name        = module.conventions.aws_naming_conventions.lambda_logging_role_name
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_logging_role.arn
}
