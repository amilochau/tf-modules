terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.62, < 5.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

module "conventions" {
  source      = "../../shared/conventions"
  conventions = var.conventions
}

data "aws_caller_identity" "caller_identity" {}

locals {
  s3_bucket_name = "${module.conventions.aws_naming_conventions.s3_bucket_name_prefix}${var.client_settings.s3_bucket_name_suffix == "" ? "" : "-"}${var.client_settings.s3_bucket_name_suffix}"
}

# ===== CLIENT S3 =====

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = local.s3_bucket_name
  force_destroy = true # only for client files, no persistent data to keep here
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "s3_object_client_files" {
  for_each = fileset("${var.client_settings.package_source_file}/", "**/*")

  bucket       = aws_s3_bucket.s3_bucket.id
  key          = each.value
  source       = "${var.client_settings.package_source_file}/${each.value}"
  etag         = filemd5("${var.client_settings.package_source_file}/${each.value}")
  content_type = lookup(module.conventions.aws_format_conventions.mime_types, regex("\\.[^.]+$", each.value), null)
}

# ===== CLOUDFRONT =====

module "cloudfront_distribution" {
  source = "./cloudfront-distribution"

  conventions = var.conventions
  distribution_settings = {
    default_root_object = var.client_settings.default_root_object
    origin_api = var.api_settings != null ? {
      domain_name     = var.api_settings.domain_name
      origin_path     = var.api_settings.origin_path
      allowed_origins = var.api_settings.allowed_origins
    } : null
    origin_client = {
      domain_name = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    }
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
}
