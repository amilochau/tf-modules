module "environment" {
  source      = "../../shared/environment"
  conventions = var.conventions
}

locals {
  aws_default_base = {
    prefix = "${var.conventions.organization_name}-${var.conventions.application_name}-${var.conventions.host_name}"
  }

  aws_naming = {
    apigateway_api_name                 = "${local.aws_default_base.prefix}-api"               # aws_apigatewayv2_api
    apigateway_authorizer_name          = "${local.aws_default_base.prefix}-authorizer"        # aws_apigatewayv2_authorizer
    cognito_userpool_name               = "${local.aws_default_base.prefix}-userpool"          # aws_cognito_user_pool
    cognito_userpool_client_name_prefix = "${local.aws_default_base.prefix}-userpool-client"   # aws_cognito_user_pool_client
    dynamodb_table_name_prefix          = "${local.aws_default_base.prefix}-table"             # aws_dynamodb_table
    iam_policy_name_prefix              = "${local.aws_default_base.prefix}-policy"            # aws_iam_policy
    iam_role_name_prefix                = "${local.aws_default_base.prefix}-role"              # aws_iam_role
    ses_identity_policy_name_prefix     = "${local.aws_default_base.prefix}-ses-policy"        # aws_ses_identity_policy
    lambda_function_name_prefix         = "${local.aws_default_base.prefix}-fn"                # aws_lambda_function
    s3_bucket_name_prefix               = "${local.aws_default_base.prefix}-bucket"            # aws_s3_bucket
    ses_template_name_prefix            = "${local.aws_default_base.prefix}-template"          # aws_ses_template
    ses_configuration_set_name          = "${local.aws_default_base.prefix}-configuration-set" # aws_sesv2_configuration_set
    sns_topic_name_prefix               = "${local.aws_default_base.prefix}-topic"             # aws_sns_topic
    eventbridge_schedule_group_name     = "${local.aws_default_base.prefix}-schedule-group"    # aws_scheduler_schedule
    eventbridge_schedule_name_prefix    = "${local.aws_default_base.prefix}-schedule"          # aws_scheduler_schedule

    cloudfront_distribution_comment        = "${local.aws_default_base.prefix}-cf"                 # aws_cloudfront_distribution
    cloudfront_origin_access_control_name  = "${local.aws_default_base.prefix}-cf-oac"             # aws_cloudfront_origin_access_control
    cloudfront_cache_policy_name           = "${local.aws_default_base.prefix}-cf-cache-policy"    # aws_cloudfront_cache_policy
    cloudfront_origin_request_policy_name  = "${local.aws_default_base.prefix}-cf-request-policy"  # aws_cloudfront_origin_request_policy
    cloudfront_response_header_policy_name = "${local.aws_default_base.prefix}-cf-response-policy" # aws_cloudfront_response_headers_policy
  }
}

locals {
  aws_existing = {
    cloudfront_cache_policy_disabled_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html#managed-cache-policy-caching-disabled
    cloudfront_cache_policy_optimized_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html#managed-cache-policy-caching-disabled
  }
}

locals {
  aws_format = {
    cloudwatch_log_group_retention_days      = 30
    cognito_auth_session_validity_minutes    = 5
    cognito_access_token_validity_minutes    = 60
    cognito_id_token_validity_minutes        = 60
    cognito_refresh_token_validity_days      = 365
    mime_types                               = jsondecode(file("${path.module}/data/mime.json"))
    eventbridge_schedule_flexible_window_min = 10
    eventbridge_schedule_retries             = 2
    eventbridge_schedule_event_age_sec       = 600 # 10 min
    apigateway_throttling_burst_limit        = 10
    apigateway_throttling_rate_limit         = 10
    apigateway_accesslog_format              = jsonencode(file("${path.module}/data/apigateway_accesslog_format.json"))
    urlparse_regex                           = "(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?(?P<path>[^?#]*)(?:\\?(?P<query>[^#]*))?(?:#(?P<fragment>.*))?" # https://github.com/hashicorp/terraform/issues/23893
  }
}
