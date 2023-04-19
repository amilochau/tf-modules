module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

locals {
  to_archive       = var.function_settings.deployment_source_file_path != null && length(var.function_settings.deployment_source_file_path) > 0
  filename         = local.to_archive ? data.archive_file.package_files[0].output_path : var.function_settings.deployment_file_path
  source_code_hash = local.to_archive ? data.archive_file.package_files[0].output_base64sha256 : filebase64sha256(var.function_settings.deployment_file_path)
}

# ===== LAMBDA IAM ROLE =====

module "lambda_iam_role" {
  source = "./iam-role-assume"

  conventions = var.conventions
  function_settings = {
    function_key = var.function_settings.function_key
  }
}

# ===== LAMBDA =====

data "archive_file" "package_files" {
  count       = local.to_archive ? 1 : 0
  type        = "zip"
  source_file = var.function_settings.deployment_source_file_path
  output_path = var.function_settings.deployment_file_path
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "${module.conventions.aws_naming_conventions.lambda_function_name_prefix}-${var.function_settings.function_key}"
  role          = module.lambda_iam_role.iam_role_arn

  filename         = local.filename
  source_code_hash = local.source_code_hash
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

module cloudwatch_log_group {
  source = "./cloudwatch-log-group"

  conventions = var.conventions
  function_settings = {
    function_key = var.function_settings.function_key
    function_name = aws_lambda_function.lambda_function.function_name
  }
}

# ===== LAMBDA ACCESS TO LOG GROUP =====

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachment_logging" {
  role       = module.lambda_iam_role.iam_role_name
  policy_arn = module.cloudwatch_log_group.iam_policy_arn
}

# ===== LAMBDA IAM POLICY ACCESSES

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachments" {
  for_each = { for k, v in var.accesses_settings.iam_policy_arns : k => v }

  role       = module.lambda_iam_role.iam_role_name
  policy_arn = each.value
}

module "access_ses_identities" {
  for_each = { for k, v in var.accesses_settings.ses_domains : k => v }
  source   = "./access-ses-identity"

  conventions  = var.conventions
  ses_domain   = each.value
  function_arn = aws_lambda_function.lambda_function.arn
}

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachments_ses_identities" {
  for_each = { for k, v in module.access_ses_identities : k => v }

  role       = module.lambda_iam_role.iam_role_name
  policy_arn = each.value.iam_policy_arn
}

# ===== API GATEWAY TRIGGER =====

resource "aws_lambda_permission" "apigateway_permission" {
  count         = length(var.triggers_settings.api_gateway_routes) > 0 ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.triggers_settings.api_gateway_routes[0].api_execution_arn}/*/*" # Allow invocation from any stage, any method, any resource path @todo restrict that?
}

/*
data "aws_iam_policy_document" "api_gateway_iam_policy_document_lambda" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      var.function_settings.function_arn,
      "${var.function_settings.function_arn}:*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "api_gateway_iam_policy_lambda" {
  name = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-gateway-lambda-${var.function_settings.function_key}"
  description = "IAM policy for invoking a lambda from an API Gateway"
  policy = data.aws_iam_policy_document.api_gateway_iam_policy_document_lambda.json
}

resource "aws_iam_policy" "name" {
  
}
*/

module "trigger_api_gateway_routes" {
  for_each = { for k, v in var.triggers_settings.api_gateway_routes : k => v }
  source   = "./trigger-api-gateway-route"

  function_settings = {
    function_name = aws_lambda_function.lambda_function.function_name
    invoke_arn    = aws_lambda_function.lambda_function.invoke_arn
  }
  api_gateway_settings = each.value
}

# ===== SNS TRIGGER =====

module "trigger_sns_topics" {
  for_each = { for k, v in var.triggers_settings.sns_topics : k => v }
  source   = "./trigger-sns-topic"

  function_settings = {
    function_name = aws_lambda_function.lambda_function.function_name
    function_arn  = aws_lambda_function.lambda_function.arn
  }
  sns_settings = each.value
}

# ===== SCHEDULE TRIGGER =====

module "trigger_schedule" {
  count = length(var.triggers_settings.schedules) > 0 ? 1 : 0
  source   = "./trigger-schedule"

  conventions       = var.conventions
  function_settings = {
    function_key = var.function_settings.function_key
    function_arn  = aws_lambda_function.lambda_function.arn
  }
  schedule_settings = {
    schedule_group_name = var.accesses_settings.schedule_group_name
    schedules = [ for v in var.triggers_settings.schedules : {
      description = v.description
      schedule_expression = v.schedule_expression
    }]
  }
}
