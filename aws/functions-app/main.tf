terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.44"
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
  clients     = var.clients
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

module "lambda_iam_role" {
  source = "./lambda-iam-role"

  conventions = var.conventions
}

module "lambda_functions" {
  for_each = var.lambda_settings.functions
  source   = "./lambda-function"

  conventions = var.conventions
  settings = {
    runtime              = var.lambda_settings.runtime
    architecture         = var.lambda_settings.architecture
    deployment_file_path = var.lambda_settings.deployment_file_path
    function_key         = each.key
    memory_size_mb       = each.value.memory_size_mb
    timeout_s            = each.value.timeout_s
    handler              = each.value.handler
    http_trigger = each.value.http_trigger == null ? null : {
      method      = each.value.http_trigger.method
      route       = each.value.http_trigger.route
      anonymous   = each.value.http_trigger.anonymous
      enable_cors = each.value.http_trigger.enable_cors
    }
  }
  iam_role_settings = {
    arn  = module.lambda_iam_role.iam_role_arn
    name = module.lambda_iam_role.iam_role_name
  }
  apigateway_settings = {
    api_id            = local.has_http_triggers ? module.api_gateway_api[0].apigateway_api_id : null
    api_execution_arn = local.has_http_triggers ? module.api_gateway_api[0].apigateway_api_execution_arn : null
    authorizer_id     = local.has_http_triggers ? module.api_gateway_api[0].apigateway_authorizer_id : null
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
