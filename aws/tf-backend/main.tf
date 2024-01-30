terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26, < 6.0.0"
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

module "environment" {
  source      = "../../shared/environment"
  context = var.context
}

module "context" {
  source      = "../../shared/conventions"
  context = var.context
}

locals {
  s3_bucket_name      = "${module.conventions.aws_naming_conventions.s3_bucket_name_prefix}${var.resources_name_suffix == "" ? "" : "-"}${var.resources_name_suffix}"
  dynamodb_table_name = "${module.conventions.aws_naming_conventions.dynamodb_table_name_prefix}${var.resources_name_suffix == "" ? "" : "-"}${var.resources_name_suffix}-locks"
}

# ===== S3 BUCKET =====

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = local.s3_bucket_name
  force_destroy = var.context.temporary
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    expiration {
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days           = 30
      newer_noncurrent_versions = 5
    }
  }
}

# ===== DYNAMODB TABLE =====

resource "aws_dynamodb_table" "dynamodb_table" {
  name                        = local.dynamodb_table_name
  hash_key                    = "LockID"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = !var.context.temporary && module.environment.is_production

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = false
  }
}
