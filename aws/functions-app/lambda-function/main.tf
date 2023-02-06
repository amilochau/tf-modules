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
  name               = "${module.conventions.aws_naming_conventions.iam_role_name_prefix}-lambda-${var.function_settings.function_key}"
  description        = "IAM role used by the lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_policy_document.json
}

# ===== LAMBDA =====

resource "aws_lambda_function" "lambda_function" {
  function_name = "${module.conventions.aws_naming_conventions.lambda_function_name_prefix}-${var.function_settings.function_key}"
  role          = aws_iam_role.lambda_iam_role.arn

  filename         = var.function_settings.deployment_file_path
  source_code_hash = filebase64sha256(var.function_settings.deployment_file_path)
  runtime          = var.function_settings.runtime
  architectures    = [var.function_settings.architecture]
  timeout          = var.function_settings.timeout_s
  memory_size      = var.function_settings.memory_size_mb
  handler          = var.function_settings.handler

  environment {
    variables = merge(var.function_settings.environment_variables, {
      "CONVENTION__PREFIX"      = "${var.conventions.application_name}-${var.conventions.host_name}"
      "CONVENTION__APPLICATION" = var.conventions.application_name
      "CONVENTION__HOST"        = var.conventions.host_name
    })
  }
}

# ===== CLOUDWATCH LOG GROUP =====

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
}

# ===== LAMBDA ACCESS TO LOG GROUP =====

data "aws_iam_policy_document" "lambda_iam_policy_document_logging" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.cloudwatch_loggroup_lambda.arn}:*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "lambda_iam_policy_logging" {
  name        = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-lambda-logging-${var.function_settings.function_key}"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_iam_policy_document_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachment_logging" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy_logging.arn
}

# ===== LAMBDA IAM POLICY ACCESSES

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachments" {
  for_each = { for k, v in var.accesses_settings.iam_policy_arns: k => v }

  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = each.value
}

module "access_ses_identities" {
  for_each = { for k, v in var.accesses_settings.ses_domains: k => v }
  source = "./access-ses-identity"

  conventions = var.conventions
  ses_domain = each.value
}

# ===== API GATEWAY TRIGGER =====

module "trigger_api_gateway_routes" {
  for_each = { for k, v in var.triggers_settings.api_gateway_routes: k => v }  
  source = "./trigger-api-gateway-route"

  function_settings = {
    function_name = aws_lambda_function.lambda_function.function_name
    invoke_arn    = aws_lambda_function.lambda_function.invoke_arn
  }
  api_gateway_settings = each.value
}

# ===== SNS TRIGGER =====

module "trigger_sns_topics" {
  for_each = { for k, v in var.triggers_settings.sns_topics: k => v }
  source = "./trigger-sns-topic"

  function_settings = {
    function_name = aws_lambda_function.lambda_function.function_name
    function_arn  = aws_lambda_function.lambda_function.arn
  }
  sns_settings = each.value
}
