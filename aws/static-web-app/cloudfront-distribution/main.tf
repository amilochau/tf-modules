terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26, < 6.0.0"
      configuration_aliases = [
        aws.infrastructure,
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

locals {
  enable_cors = var.distribution_settings.origin_api != null ? length(var.distribution_settings.origin_api.allowed_origins) > 0 : false
}

resource "aws_cloudfront_origin_access_control" "cloudfront_s3_access_control" {
  name                              = module.conventions.aws_naming_conventions.cloudfront_origin_access_control_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  provider = aws.workloads
}

resource "aws_cloudfront_cache_policy" "cloudfront_cache_api" {
  name        = module.conventions.aws_naming_conventions.cloudfront_cache_policy_name
  comment     = "Cache policy for API"
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 1 # Does not work if caching is disabled

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization"] # https://aws.amazon.com/premiumsupport/knowledge-center/cloudfront-authorization-header
      }
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }

  provider = aws.workloads
}

resource "aws_cloudfront_origin_request_policy" "cloudfront_origin_request_api" {
  name    = module.conventions.aws_naming_conventions.cloudfront_origin_request_policy_name
  comment = "Origin request policy for API"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "all"
  }

  provider = aws.workloads
}

resource "aws_cloudfront_response_headers_policy" "cloudfront_response_header_api" {
  count   = local.enable_cors ? 1 : 0
  name    = module.conventions.aws_naming_conventions.cloudfront_response_header_policy_name
  comment = "Response header policy for API"

  cors_config {
    access_control_allow_credentials = true
    origin_override                  = true

    access_control_allow_headers {
      items = ["Authorization", "Content-Type"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "PUT", "POST", "PATCH", "DELETE", "OPTIONS"]
    }
    access_control_allow_origins {
      items = var.distribution_settings.origin_api.allowed_origins
    }
  }

  provider = aws.workloads
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  comment             = module.conventions.aws_naming_conventions.cloudfront_distribution_comment
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = "PriceClass_100"
  wait_for_deployment = false
  default_root_object = var.distribution_settings.default_root_object
  aliases             = var.distribution_settings.domains != null ? var.distribution_settings.domains.alternate_domain_names : []

  dynamic "origin" {
    for_each = var.distribution_settings.origin_api != null ? [0] : []
    content {
      origin_id   = "api"
      domain_name = var.distribution_settings.origin_api.domain_name
      origin_path = var.distribution_settings.origin_api.origin_path
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }
  origin {
    origin_id                = "client"
    domain_name              = var.distribution_settings.origin_client.domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_s3_access_control.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "client"
    cache_policy_id        = module.conventions.aws_existing_conventions.cloudfront_cache_policy_disabled_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.distribution_settings.origin_api != null ? [0] : []
    content {
      path_pattern               = "/api/*"
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD", "OPTIONS"]
      target_origin_id           = "api"
      cache_policy_id            = aws_cloudfront_cache_policy.cloudfront_cache_api.id
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.cloudfront_origin_request_api.id
      response_headers_policy_id = local.enable_cors ? aws_cloudfront_response_headers_policy.cloudfront_response_header_api[0].id : null
      viewer_protocol_policy     = "https-only"
      compress                   = true
    }
  }
  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "client"
    cache_policy_id        = module.conventions.aws_existing_conventions.cloudfront_cache_policy_optimized_id
    viewer_protocol_policy = "https-only"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/${var.distribution_settings.default_root_object}"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/${var.distribution_settings.default_root_object}"
    error_caching_min_ttl = 0
  }

  dynamic "viewer_certificate" {
    for_each = var.distribution_settings.domains != null ? [] : [0]

    content {
      cloudfront_default_certificate = true
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.distribution_settings.domains != null ? [0] : []

    content {
      acm_certificate_arn      = var.distribution_settings.domains.certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  provider = aws.workloads
}

data "aws_route53_zone" "route53_zone" {
  count = var.distribution_settings.domains != null ? 1 : 0
  name  = var.distribution_settings.domains.zone_name

  provider = aws.infrastructure
}

resource "aws_route53_record" "route53_record_ipv4" {
  for_each = { for v in var.distribution_settings.domains != null ? lookup(var.distribution_settings.domains, "alternate_domain_names", []) : [] : v => v }

  zone_id = data.aws_route53_zone.route53_zone[0].zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }

  provider = aws.infrastructure
}

resource "aws_route53_record" "route53_record_ipv6" {
  for_each = { for v in var.distribution_settings.domains != null ? lookup(var.distribution_settings.domains, "alternate_domain_names", []) : [] : v => v }

  zone_id = data.aws_route53_zone.route53_zone[0].zone_id
  name    = each.value
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }

  provider = aws.infrastructure
}
