module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name = "${module.conventions.aws_naming_conventions.dynamodb_table_name_prefix}-${var.table_settings.name}"
  hash_key = var.table_settings.partition_key
  range_key = var.table_settings.sort_key
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = var.table_settings.partition_key
    type = "S"
  }

  dynamic attribute {
    for_each = var.table_settings.sort_key != null ? [1] : []
    content {
      name = var.table_settings.sort_key
      type = "S"
    }
  }

  server_side_encryption {
    enabled = false
  }

  dynamic ttl {
    for_each = var.table_settings.ttl.enabled ? [1] : []
    content {
      enabled = true
      attribute_name = var.table_settings.ttl.attribute_name
    }
  }
  
  dynamic global_secondary_index {
    for_each = var.table_settings.global_secondary_indexes
    content {
      name               = global_secondary_index.key
      hash_key           = global_secondary_index.value.partition_key
      range_key          = global_secondary_index.value.sort_key
      projection_type    = "INCLUDE"
      non_key_attributes = global_secondary_index.value.non_key_attributes
    }
  }
}
