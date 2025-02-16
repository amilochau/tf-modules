terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
      configuration_aliases = [
        aws.infrastructure,
        aws.workloads,
        aws.workloads-us-east
      ]
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
}

module "conventions" {
  source  = "../../shared/conventions"
  context = var.context
}

data "aws_caller_identity" "caller_identity" {
  provider = aws.workloads
}

locals {
  s3_bucket_name = "${module.conventions.aws_naming_conventions.s3_bucket_name_prefix}${var.client_settings.s3_bucket_name_suffix == "" ? "" : "-"}${var.client_settings.s3_bucket_name_suffix}"
}

# ===== CLIENT S3 =====

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = local.s3_bucket_name
  force_destroy = true # only for client files, no persistent data to keep here

  provider = aws.workloads
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  provider = aws.workloads
}

resource "aws_s3_object" "s3_object_client_files" {
  for_each = fileset("${var.client_settings.package_source_file}/", "**/*")

  bucket       = aws_s3_bucket.s3_bucket.id
  key          = each.value
  source       = "${var.client_settings.package_source_file}/${each.value}"
  etag         = filemd5("${var.client_settings.package_source_file}/${each.value}")
  content_type = lookup(module.conventions.aws_format_conventions.mime_types, regex("\\.[^.]+$", each.value), null)

  override_provider {
    default_tags {
      tags = {}
    }
  }

  provider = aws.workloads
}

# ===== CLOUDFRONT CERTIFICATE =====

module "cloudfront_certificate" {
  count  = var.client_settings.domains != null ? 1 : 0
  source = "./cloudfront-certificate"

  certificate_settings = var.client_settings.domains

  providers = {
    aws.infrastructure    = aws.infrastructure
    aws.workloads-us-east = aws.workloads-us-east
  }
}

# ===== CLOUDFRONT DISTRIBUTION =====

module "cloudfront_distribution" {
  source = "./cloudfront-distribution"

  context = var.context
  distribution_settings = {
    origin_api = var.api_settings != null ? {
      domain_name     = var.api_settings.domain_name
      origin_path     = var.api_settings.origin_path
      allowed_origins = var.api_settings.allowed_origins
    } : null
    origin_client = {
      client_type = var.client_settings.client_type
      domain_name = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    }
    domains = var.client_settings.domains != null ? {
      zone_name              = var.client_settings.domains.zone_name
      alternate_domain_names = flatten([[var.client_settings.domains.domain_name], var.client_settings.domains.subject_alternative_names])
      certificate_arn        = module.cloudfront_certificate[0].certificate_arn
    } : null
  }

  providers = {
    aws.infrastructure = aws.infrastructure
    aws.workloads      = aws.workloads
  }
}

data "aws_iam_policy_document" "cloudfront_s3_bucket_policy_document" {
  statement {
    sid = "AllowCloudFrontServicePrincipalReadOnly"

    principals {
      type = "Service"
      identifiers = [
        "cloudfront.amazonaws.com"
      ]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values = [
        data.aws_caller_identity.caller_identity.account_id
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        module.cloudfront_distribution.cloudfront_distribution_arn
      ]
    }
    effect = "Allow"
  }
}

resource "aws_s3_bucket_policy" "cloudfront_s3_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.cloudfront_s3_bucket_policy_document.json

  provider = aws.workloads
}
