terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.59.0, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.9.2, < 2.0.0"
}

locals {
  has_http_triggers = anytrue([for v in var.lambda_settings.functions : length(v.http_triggers) > 0])
  has_schedules     = anytrue([for v in var.lambda_settings.functions : length(v.scheduler_triggers) > 0])
}

module "cloudwatch_log_group" {
  source = "./cloudwatch-log-group"

  context = var.context

  providers = {
    aws.workloads = aws.workloads
  }
}

module "cognito_clients" {
  count  = local.has_http_triggers ? 1 : 0
  source = "./cognito-clients"

  context              = var.context
  cognito_user_pool_id = var.cognito_user_pool_id
  clients_settings     = var.cognito_clients_settings

  providers = {
    aws.workloads = aws.workloads
  }
}

module "dynamodb_tables" {
  for_each = var.dynamodb_tables_settings
  source   = "./dynamodb-table"

  context = var.context
  table_settings = {
    name                     = each.key
    partition_key            = each.value.partition_key
    sort_key                 = each.value.sort_key
    attributes               = each.value.attributes
    ttl                      = each.value.ttl
    global_secondary_indexes = each.value.global_secondary_indexes
    enable_stream            = each.value.enable_stream
  }

  providers = {
    aws.workloads = aws.workloads
  }
}

module "api_gateway_api" {
  count  = local.has_http_triggers ? 1 : 0
  source = "./api-gateway-api"

  context           = var.context
  enable_authorizer = anytrue([for v in var.lambda_settings.functions : anytrue([for v2 in v.http_triggers : !v2.anonymous]) if length(v.http_triggers) > 0])
  cognito_settings = {
    user_pool_id = var.cognito_user_pool_id
    client_ids   = module.cognito_clients[0].cognito_client_ids
  }
  cloudwatch_log_group_arn = module.cloudwatch_log_group.cloudwatch_log_group_arn

  providers = {
    aws.workloads = aws.workloads
  }
}

module "schedule_group" {
  count  = local.has_schedules ? 1 : 0
  source = "./schedule-group"

  context = var.context

  providers = {
    aws.workloads = aws.workloads
  }
}

module "sns_topics" {
  for_each = var.sns_topics_settings
  source   = "./sns-topic"

  context = var.context
  topic_settings = {
    name = each.key
  }

  providers = {
    aws.workloads = aws.workloads
  }
}

module "lambda_functions" {
  for_each = var.lambda_settings.functions
  source   = "./lambda-function"

  depends_on = [
    module.sns_topics
  ]

  context = var.context
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
    minimum_log_level           = each.value.minimum_log_level
  }
  triggers_settings = {
    api_gateway_routes = [for v in each.value.http_triggers : {
      description       = v.description
      api_id            = module.api_gateway_api[0].apigateway_api_id
      api_execution_arn = module.api_gateway_api[0].apigateway_api_execution_arn
      authorizer_id     = module.api_gateway_api[0].apigateway_authorizer_id
      method            = v.method
      route             = v.route
      anonymous         = v.anonymous
      enable_cors       = v.enable_cors
    }]
    sns_topics = [for v in each.value.sns_triggers : {
      description = v.description
      topic_arn   = v.topic_arn
    }]
    schedules = [for v in each.value.scheduler_triggers : {
      description         = v.description
      schedule_expression = v.schedule_expression
      enabled             = v.enabled
    }]
    dynamodb_streams = [for v in each.value.dynamodb_stream_triggers : {
      description                        = v.description
      stream_arn                         = module.dynamodb_tables[v.table_name].stream_arn
      filter_criteria_patterns           = v.filter_criteria_patterns
      batch_size                         = v.batch_size
      maximum_batching_window_in_seconds = v.maximum_batching_window_in_seconds
      maximum_retry_attempts             = v.maximum_retry_attempts
    }]
  }
  accesses_settings = {
    ses_domains              = [for k, v in each.value.ses_accesses : v.domain]
    lambda_arns              = [for k, v in each.value.lambda_accesses : v.arn]
    schedule_group_name      = local.has_schedules ? module.schedule_group[0].schedule_group_name : null
    dynamodb_table_arns      = [for k, v in module.dynamodb_tables : v.table_arn]
    sns_topics_arns          = [for k, v in module.sns_topics : v.topic_arn]
    cognito_userpools_access = each.value.cognito_userpools_access
  }
  monitoring_settings = {
    cloudwatch_log_group_arn  = module.cloudwatch_log_group.cloudwatch_log_group_arn
    cloudwatch_log_group_name = module.cloudwatch_log_group.cloudwatch_log_group_name
  }

  providers = {
    aws.workloads = aws.workloads
  }
}
