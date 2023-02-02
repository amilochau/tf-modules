module "environment" {
  source      = "../../shared/environment"
  conventions = var.conventions
}

locals {
  aws_default_base = {
    prefix = "${var.conventions.application_name}-${var.conventions.host_name}"
  }

  aws_naming = {
    apigateway_api_name                 = "${local.aws_default_base.prefix}-api"               # aws_apigatewayv2_api
    apigateway_authorizer_name          = "${local.aws_default_base.prefix}-authorizer"        # aws_apigatewayv2_authorizer
    cognito_userpool_name               = "${local.aws_default_base.prefix}-userpool"          # aws_cognito_user_pool
    cognito_userpool_client_name_prefix = "${local.aws_default_base.prefix}-userpool-client"   # aws_cognito_user_pool_client
    dynamodb_table_name_prefix          = "${local.aws_default_base.prefix}-table"             # aws_dynamodb_table
    iam_policy_name_prefix              = "${local.aws_default_base.prefix}-policy"            # aws_iam_policy
    iam_role_name_prefix                = "${local.aws_default_base.prefix}-role"              # aws_iam_role
    lambda_function_name_prefix         = "${local.aws_default_base.prefix}-fn"                # aws_lambda_function
    s3_bucket_name                      = "${local.aws_default_base.prefix}-bucket"            # aws_s3_bucket
    ses_template_name_prefix            = "${local.aws_default_base.prefix}-template"          # aws_ses_template
    ses_configuration_set_name          = "${local.aws_default_base.prefix}-configuration-set" # aws_sesv2_configuration_set
    sns_topic_name_prefix               = "${local.aws_default_base.prefix}-topic"             # aws_sns_topic
  }
}

locals {
  aws_environment_base = {
    host = module.environment.is_production ? "prd" : "dev"
  }

  aws_existing = {
    cognito_userpool_name = "identity-${local.aws_environment_base.host}-userpool"
  }
}

locals {
  aws_format = {
    cloudwatch_log_group_retention_days = 30
    mime_types                          = jsondecode(file("${path.module}/data/mime.json"))
    apigateway_accesslog_format         = jsonencode(file("${path.module}/data/apigateway_accesslog_format.json"))
  }
}
