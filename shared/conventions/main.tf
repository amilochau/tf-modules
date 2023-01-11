module "environment" {
  source      = "../../shared/environment"
  conventions = var.conventions
}

locals {
  aws_default_base = {
    prefix = "${var.conventions.organization_name}-${var.conventions.application_name}-${var.conventions.host_name}"
  }

  aws_naming = {
    cognito_userpool_name            = "${local.aws_default_base.prefix}-cognito-userpool"
    lambda_function_name             = "${local.aws_default_base.prefix}-lambda-fn"
    lambda_iam_role_name             = "${local.aws_default_base.prefix}-lambda-role-iam"
    lambda_logging_role_name         = "${local.aws_default_base.prefix}-lambda-role-logging"
    apigateway_api_name              = "${local.aws_default_base.prefix}-apigateway-api"
    apigateway_authorizer_name       = "${local.aws_default_base.prefix}-apigateway-authorizer"
    apigateway_stage_name            = var.conventions.host_name
    cognito_userpool_client_api_name = "${local.aws_default_base.prefix}-cognito-client-api"
    s3_bucket_name                   = "${local.aws_default_base.prefix}-s3-bucket"
  }
}

locals {
  aws_environment_base = {
    host = module.environment.is_production ? "prd" : "dev"
  }

  aws_existing = {
    cognito_userpool_name = "${var.conventions.organization_name}-identity-${local.aws_environment_base.host}-cognito-userpool"
  }
}

locals {
  aws_format = {
    cloudwatch_log_group_retention_days = 30
    mime_types                          = jsondecode(file("${path.module}/data/mime.json"))
    apigateway_accesslog_format         = jsonencode(file("${path.module}/data/apigateway_accesslog_format.json"))
  }
}
