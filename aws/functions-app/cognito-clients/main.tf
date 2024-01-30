terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

module "conventions" {
  source  = "../../../shared/conventions"
  context = var.context
}

data "aws_cognito_user_pools" "cognito_userpool" {
  name = var.cognito_user_pool_name

  provider = aws.workloads
}

locals {
  cognito_user_pool_id = data.aws_cognito_user_pools.cognito_userpool.ids[0]
}

# ===== COGNITO CLIENTS =====

resource "aws_cognito_user_pool_client" "cognito_userpool_client_temporary" {
  for_each = var.context.temporary ? var.clients_settings : {}
  name     = "${module.conventions.aws_naming_conventions.cognito_userpool_client_name_prefix}-${each.key}"

  user_pool_id                  = local.cognito_user_pool_id
  generate_secret               = false
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"

  access_token_validity  = module.conventions.aws_format_conventions.cognito_access_token_validity_minutes
  id_token_validity      = module.conventions.aws_format_conventions.cognito_id_token_validity_minutes
  refresh_token_validity = module.conventions.aws_format_conventions.cognito_refresh_token_validity_days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  explicit_auth_flows = each.value.disable_users_migration ? [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    ] : [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  provider = aws.workloads
}

resource "aws_cognito_user_pool_client" "cognito_userpool_client" {
  for_each = var.context.temporary ? {} : var.clients_settings
  name     = "${module.conventions.aws_naming_conventions.cognito_userpool_client_name_prefix}-${each.key}"

  user_pool_id                  = local.cognito_user_pool_id
  generate_secret               = false
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"

  access_token_validity  = module.conventions.aws_format_conventions.cognito_access_token_validity_minutes
  id_token_validity      = module.conventions.aws_format_conventions.cognito_id_token_validity_minutes
  refresh_token_validity = module.conventions.aws_format_conventions.cognito_refresh_token_validity_days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  explicit_auth_flows = each.value.disable_users_migration ? [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    ] : [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  lifecycle {
    prevent_destroy = true # As we can't use var.context.temporary in lifecycle, we have to duplicate this block...
  }

  provider = aws.workloads
}
