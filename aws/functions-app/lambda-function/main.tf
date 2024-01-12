module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

locals {
  to_archive       = var.function_settings.deployment_source_file_path != null && length(var.function_settings.deployment_source_file_path) > 0
  filename         = local.to_archive ? data.archive_file.package_files[0].output_path : var.function_settings.deployment_file_path
  source_code_hash = local.to_archive ? data.archive_file.package_files[0].output_base64sha256 : filebase64sha256(var.function_settings.deployment_file_path)
}

# ===== LAMBDA EXECUTION ROLE =====

module "lambda_iam_role" {
  source = "./iam-role"

  conventions = var.conventions
  function_settings = {
    function_key = var.function_settings.function_key
  }
  accesses_settings = {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.cloudwatch_loggroup_lambda.arn
    dynamodb_table_arns      = var.accesses_settings.dynamodb_table_arns
    dynamodb_stream_arns     = var.triggers_settings.dynamodb_streams.*.stream_arn
    ses_domain_identity_arns = values(module.ses_identity_policies)[*].ses_identity_arn
    lambda_arns              = var.accesses_settings.lambda_arns
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
      "CONVENTION__PREFIX"       = "${var.conventions.organization_name}-${var.conventions.application_name}-${var.conventions.host_name}"
      "CONVENTION__ORGANIZATION" = var.conventions.organization_name
      "CONVENTION__APPLICATION"  = var.conventions.application_name
      "CONVENTION__HOST"         = var.conventions.host_name
    })
  }

  tracing_config {
    mode = "Active"
  }
}

# ===== CLOUDWATCH LOG GROUP =====

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
  skip_destroy      = !var.conventions.temporary
}

# ===== LAMBDA SES DOMAIN IDENTITY POLICIES

module "ses_identity_policies" {
  for_each = { for k, v in var.accesses_settings.ses_domains : k => v }
  source   = "./ses-identity-policy"

  conventions  = var.conventions
  ses_domain   = each.value
  function_arn = aws_lambda_function.lambda_function.arn
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

module "trigger_api_gateway_routes" {
  for_each = { for k, v in var.triggers_settings.api_gateway_routes : k => v }
  source   = "./trigger-api-gateway-route"

  function_settings = {
    invoke_arn = aws_lambda_function.lambda_function.invoke_arn
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
  count  = length(var.triggers_settings.schedules) > 0 ? 1 : 0
  source = "./trigger-schedule"

  conventions = var.conventions
  function_settings = {
    function_key = var.function_settings.function_key
    function_arn = aws_lambda_function.lambda_function.arn
  }
  schedule_settings = {
    schedule_group_name = var.accesses_settings.schedule_group_name
    schedules = [for v in var.triggers_settings.schedules : {
      description         = v.description
      schedule_expression = v.schedule_expression
      enabled             = v.enabled
    }]
  }
}

# ===== DYNAMODB STREAM TRIGGER =====

module "dynamodb_stream_trigger" {
  for_each = { for k, v in var.triggers_settings.dynamodb_streams : k => v }
  source   = "./trigger-dynamodb-stream"

  function_settings = {
    function_name = aws_lambda_function.lambda_function.function_name
  }

  dynamodb_stream_settings = each.value
}
