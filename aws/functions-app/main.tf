terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.44"
    }
  }

  required_version = ">= 1.3.0"
}

module "lambda" {
  source = "./lambda"

  conventions = var.conventions
  settings = var.lambda_settings
}

module "cognito_clients" {
  source = "./cognito-clients"

  conventions = var.conventions
  clients = var.clients
}

module "api_gateway" {
  source = "./api-gateway"

  conventions = var.conventions
  functions_outputs = {
    function_name = module.lambda.function_name
    invoke_arn = module.lambda.invoke_arn
  }
  cognito_outputs = {
    user_pool_id = module.cognito_clients.cognito_user_pool_id
    client_ids = module.cognito_clients.cognito_client_ids
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
