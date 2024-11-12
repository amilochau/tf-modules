terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
}

module "conventions" {
  source  = "../../../shared/conventions"
  context = var.context
}

locals {
  to_archive       = var.function_settings.deployment_source_file_path != null && length(var.function_settings.deployment_source_file_path) > 0
  filename         = local.to_archive ? data.archive_file.package_files[0].output_path : var.function_settings.deployment_file_path
  source_code_hash = local.to_archive ? data.archive_file.package_files[0].output_base64sha256 : filebase64sha256(var.function_settings.deployment_file_path)
}

# ===== LAMBDA EXECUTION ROLE =====

module "lambda_iam_role" {
  source = "./iam-role"

  context = var.context
  function_settings = {
    function_key = var.function_settings.function_key
  }
  accesses_settings = {
    cloudwatch_log_group_arn = var.monitoring_settings.cloudwatch_log_group_arn
    dynamodb_table_arns      = var.accesses_settings.dynamodb_table_arns
    dynamodb_stream_arns     = var.triggers_settings.dynamodb_streams.*.stream_arn
    sns_topics_arns          = var.accesses_settings.sns_topics_arns
    ses_domain_identity_arns = values(module.ses_identity_policies)[*].ses_identity_arn
    lambda_arns              = var.accesses_settings.lambda_arns
    cognito_userpools_access = var.accesses_settings.cognito_userpools_access
  }

  providers = {
    aws.workloads = aws.workloads
  }
}

# ===== LAMBDA =====

data "archive_file" "package_files" {
  count       = local.to_archive ? 1 : 0
  type        = "zip"
  source_file = var.function_settings.deployment_source_file_path
  output_path = var.function_settings.deployment_file_path
}

data "aws_caller_identity" "workloads" {
  provider = aws.workloads
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
      "CONVENTION__PREFIX"       = "${var.context.organization_name}-${var.context.application_name}-${var.context.host_name}"
      "CONVENTION__ORGANIZATION" = var.context.organization_name
      "CONVENTION__APPLICATION"  = var.context.application_name
      "CONVENTION__HOST"         = var.context.host_name
      "ACCOUNT_ID"               = data.aws_caller_identity.workloads.account_id
    })
  }

  tracing_config {
    mode = "Active"
  }

  logging_config {
    log_format            = "JSON"
    system_log_level      = var.function_settings.minimum_log_level
    application_log_level = var.function_settings.minimum_log_level
    log_group             = var.monitoring_settings.cloudwatch_log_group_name
  }

  provider = aws.workloads
}

# ===== LAMBDA SES DOMAIN IDENTITY POLICIES

module "ses_identity_policies" {
  for_each = { for k, v in var.accesses_settings.ses_domains : k => v }
  source   = "./ses-identity-policy"

  context      = var.context
  ses_domain   = each.value
  function_arn = aws_lambda_function.lambda_function.arn

  providers = {
    aws.workloads = aws.workloads
  }
}

# ===== API GATEWAY TRIGGER =====

resource "aws_lambda_permission" "apigateway_permission" {
  count         = length(var.triggers_settings.api_gateway_routes) > 0 ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.triggers_settings.api_gateway_routes[0].api_execution_arn}/*/*" # Allow invocation from any stage, any method, any resource path @todo restrict that?

  provider = aws.workloads
}

module "trigger_api_gateway_routes" {
  for_each = { for k, v in var.triggers_settings.api_gateway_routes : k => v }
  source   = "./trigger-api-gateway-route"

  function_settings = {
    invoke_arn = aws_lambda_function.lambda_function.invoke_arn
  }
  api_gateway_settings = each.value

  providers = {
    aws.workloads = aws.workloads
  }
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

  providers = {
    aws.workloads = aws.workloads
  }
}

# ===== SCHEDULE TRIGGER =====

module "trigger_schedule" {
  count  = length(var.triggers_settings.schedules) > 0 ? 1 : 0
  source = "./trigger-schedule"

  context = var.context
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

  providers = {
    aws.workloads = aws.workloads
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

  providers = {
    aws.workloads = aws.workloads
  }
}
