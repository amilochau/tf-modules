module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name = "${module.conventions.aws_naming_conventions.dynamodb_table_name_prefix}-${var.table_settings.name}"
  hash_key = var.table_settings.primary_key
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = var.table_settings.primary_key
    type = "S"
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
}
