module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

data "aws_cognito_user_pools" "cognito_userpool" {
  name = module.conventions.aws_existing_conventions.cognito_userpool_name
}

locals {
  cognito_user_pool_id = data.aws_cognito_user_pools.cognito_userpool.ids[0]
}

# ===== COGNITO CLIENTS =====

resource "aws_cognito_user_pool_client" "cognito_userpool_client" {
  for_each = var.clients_settings
  name     = "${module.conventions.aws_naming_conventions.cognito_userpool_client_name_prefix}-${each.key}"

  user_pool_id                  = local.cognito_user_pool_id
  generate_secret               = false
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  lifecycle {
    prevent_destroy = !var.conventions.temporary
  }
}
