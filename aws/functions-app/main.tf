terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.50, < 5.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

locals {
  has_http_triggers = anytrue([for v in var.lambda_settings.functions : v.http_trigger != null])
}

module "cognito_clients" {
  source = "./cognito-clients"

  conventions = var.conventions
  clients_settings     = var.cognito_clients_settings
}

module "dynamodb_tables" {
  for_each = var.dynamodb_tables_settings
  source = "./dynamodb-table"
  
  conventions = var.conventions
  table_settings = {
    name = each.key
    primary_key = each.value.primary_key
    ttl = each.value.ttl
  }
}

module "api_gateway_api" {
  count  = local.has_http_triggers ? 1 : 0
  source = "./api-gateway-api"

  conventions       = var.conventions
  enable_authorizer = anytrue([for v in var.lambda_settings.functions : !v.http_trigger.anonymous if v.http_trigger != null])
  cognito_settings = {
    user_pool_id = module.cognito_clients.cognito_user_pool_id
    client_ids   = module.cognito_clients.cognito_client_ids
  }
}

module "lambda_functions" {
  for_each = var.lambda_settings.functions
  source   = "./lambda-function"

  conventions = var.conventions
  settings = {
    runtime              = var.lambda_settings.runtime
    architecture         = var.lambda_settings.architecture
    function_key         = each.key
    memory_size_mb       = each.value.memory_size_mb
    timeout_s            = each.value.timeout_s
    deployment_file_path = each.value.deployment_file_path
    handler              = each.value.handler
    http_trigger = each.value.http_trigger == null ? null : {
      method      = each.value.http_trigger.method
      route       = each.value.http_trigger.route
      anonymous   = each.value.http_trigger.anonymous
      enable_cors = each.value.http_trigger.enable_cors
    }
  }
  apigateway_settings = {
    api_id            = local.has_http_triggers ? module.api_gateway_api[0].apigateway_api_id : null
    api_execution_arn = local.has_http_triggers ? module.api_gateway_api[0].apigateway_api_execution_arn : null
    authorizer_id     = local.has_http_triggers ? module.api_gateway_api[0].apigateway_authorizer_id : null
  }
  dynamodb_settings = {
    for k, v in module.dynamodb_tables: k => {
      table_name = v.table_name
      table_arn = v.table_arn
    }
  }
}

# ===== COGNITO CLIENT FOR API =====

#resource "aws_cognito_user_pool_client" "cognito_userpool_client_api" {
#  name         = module.conventions.aws_naming_conventions.cognito_userpool_client_api_name
#  user_pool_id = data.aws_cognito_user_pools.cognito_userpool.ids[0]
#  allowed_oauth_flows = [
#    "code"
#  ]
#  allowed_oauth_scopes = [
#    "email",
#    "openid"
#  ]
#  allowed_oauth_flows_user_pool_client = true
#  callback_urls = [
#    aws_apigatewayv2_stage.apigateway_stage.invoke_url
#  ]
#  explicit_auth_flows = [
#    "ALLOW_USER_PASSWORD_AUTH",
#    "ALLOW_REFRESH_TOKEN_AUTH"
#  ]
#  supported_identity_providers = ["COGNITO"]
#}
