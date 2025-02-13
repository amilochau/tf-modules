terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
      configuration_aliases = [
        aws.infrastructure,
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
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

resource "aws_cloudfront_response_headers_policy" "cloudfront_response_headers_policy_api" {
  name    = "${module.conventions.aws_naming_conventions.cloudfront_response_header_policy_name}-api"
  comment = "Response header policy for API"

  dynamic "cors_config" {
    for_each = local.enable_cors ? [1] : []
    content {
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
  }

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      override                   = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    content_type_options {
      override = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }
  }

  provider = aws.workloads
}

resource "aws_cloudfront_response_headers_policy" "cloudfront_response_headers_policy_assets" {
  name    = "${module.conventions.aws_naming_conventions.cloudfront_response_header_policy_name}-assets"
  comment = "Response header policy for assets"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "max-age=31536000, immutable"
      override = true
    }
  }

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      override                   = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    content_type_options {
      override = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
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
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = "client"
    cache_policy_id            = module.conventions.aws_existing_conventions.cloudfront_cache_policy_cachingdisabled_id                  # Managed: CachingOptimized
    origin_request_policy_id   = null                                                                                                    # [Nothing included by default]
    response_headers_policy_id = module.conventions.aws_existing_conventions.cloudfront_response_headers_policy_securityheaderspolicy_id # Managed: SecurityHeadersPolicy
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    smooth_streaming           = true
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.distribution_settings.origin_api != null ? [0] : []
    content {
      path_pattern               = "/api/*"
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD", "OPTIONS"]
      target_origin_id           = "api"
      cache_policy_id            = module.conventions.aws_existing_conventions.cloudfront_cache_policy_cachingdisabled_id                       # Managed: CachingDisabled
      origin_request_policy_id   = module.conventions.aws_existing_conventions.cloudfront_origin_request_policy_allviewerexcepthostheader_id.id # Managed: AllViewerExceptHost (host can't be forwarded to API Gateway to avoid 403)
      response_headers_policy_id = aws_cloudfront_response_headers_policy.cloudfront_response_headers_policy_api.id                             # Custom: CORS + Security
      viewer_protocol_policy     = "https-only"
      compress                   = true
      smooth_streaming           = true
    }
  }
  ordered_cache_behavior {
    path_pattern               = "/assets/*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = "client"
    cache_policy_id            = module.conventions.aws_existing_conventions.cloudfront_cache_policy_cachingoptimized_id # Managed: CachingOptimized
    origin_request_policy_id   = null                                                                                    # [Nothing included by default]
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cloudfront_response_headers_policy_assets.id     # Custom: Cache + Security
    viewer_protocol_policy     = "https-only"
    compress                   = true
    smooth_streaming           = true
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
