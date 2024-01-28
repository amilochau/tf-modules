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

module "environment" {
  source      = "../../../shared/environment"
  conventions = var.conventions
}

module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

locals {
  attributes = merge(var.table_settings.attributes, {
    "${var.table_settings.partition_key}" = {
      type = "S"
    }
    }, var.table_settings.sort_key != null ? {
    "${var.table_settings.sort_key}" = {
      type = "S"
    }
  } : {})
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name                        = "${module.conventions.aws_naming_conventions.dynamodb_table_name_prefix}-${var.table_settings.name}"
  hash_key                    = var.table_settings.partition_key
  range_key                   = var.table_settings.sort_key
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = !var.conventions.temporary && module.environment.is_production
  stream_enabled              = var.table_settings.enable_stream
  stream_view_type            = "NEW_AND_OLD_IMAGES"

  dynamic "attribute" {
    for_each = local.attributes
    content {
      name = attribute.key
      type = attribute.value.type
    }
  }

  server_side_encryption {
    enabled = false
  }

  dynamic "ttl" {
    for_each = var.table_settings.ttl.enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = var.table_settings.ttl.attribute_name
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.table_settings.global_secondary_indexes
    content {
      name               = global_secondary_index.key
      hash_key           = global_secondary_index.value.partition_key
      range_key          = global_secondary_index.value.sort_key
      projection_type    = length(global_secondary_index.value.non_key_attributes) > 0 ? "INCLUDE" : "KEYS_ONLY"
      non_key_attributes = global_secondary_index.value.non_key_attributes
    }
  }

  provider = aws.workloads
}
