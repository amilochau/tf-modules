terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.62, < 5.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

locals {
  has_http_triggers = anytrue([for v in var.lambda_settings.functions : length(v.http_triggers) > 0])
  has_schedules = anytrue([for v in var.lambda_settings.functions : length(v.scheduler_triggers) > 0])
}

module "cognito_clients" {
  source = "./cognito-clients"

  conventions      = var.conventions
  clients_settings = var.cognito_clients_settings
}

module "dynamodb_tables" {
  for_each = var.dynamodb_tables_settings
  source   = "./dynamodb-table"

  conventions = var.conventions
  table_settings = {
    name                     = each.key
    partition_key            = each.value.partition_key
    sort_key                 = each.value.sort_key
    attributes               = each.value.attributes
    ttl                      = each.value.ttl
    global_secondary_indexes = each.value.global_secondary_indexes
  }
}

module "api_gateway_api" {
  count  = local.has_http_triggers ? 1 : 0
  source = "./api-gateway-api"

  conventions       = var.conventions
  enable_authorizer = anytrue([for v in var.lambda_settings.functions : anytrue([for v2 in v.http_triggers : !v2.anonymous]) if length(v.http_triggers) > 0])
  cognito_settings = {
    user_pool_id = module.cognito_clients.cognito_user_pool_id
    client_ids   = module.cognito_clients.cognito_client_ids
  }
}

module "schedule_group" {
  count  = local.has_schedules ? 1 : 0
  source = "./schedule-group"

  conventions = var.conventions
}

module "lambda_functions" {
  for_each = var.lambda_settings.functions
  source   = "./lambda-function"

  conventions = var.conventions
  function_settings = {
    runtime                     = var.lambda_settings.runtime
    architecture                = var.lambda_settings.architecture
    function_key                = each.key
    memory_size_mb              = each.value.memory_size_mb
    timeout_s                   = each.value.timeout_s
    deployment_source_file_path = each.value.deployment_source_file_path
    deployment_file_path        = each.value.deployment_file_path
    handler                     = each.value.handler
    environment_variables       = each.value.environment_variables
  }
  triggers_settings = {
    api_gateway_routes = [for v in each.value.http_triggers : {
      api_id            = module.api_gateway_api[0].apigateway_api_id
      api_execution_arn = module.api_gateway_api[0].apigateway_api_execution_arn
      authorizer_id     = module.api_gateway_api[0].apigateway_authorizer_id
      method            = v.method
      route             = v.route
      anonymous         = v.anonymous
      enable_cors       = v.enable_cors
    }]
    sns_topics = [for v in each.value.sns_triggers : {
      topic_name = v.topic_name
    }]
    schedules = [for v in each.value.scheduler_triggers : {
      schedule_expression = v.schedule_expression
    }]
  }
  accesses_settings = {
    iam_policy_arns = [for k, v in module.dynamodb_tables : v.iam_policy_arn]
    ses_domains     = [for k, v in each.value.ses_accesses : v.domain]
    schedule_group_name = local.has_schedules ? module.schedule_group[0].schedule_group_name : null
  }
}
