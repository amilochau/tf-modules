variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
}

variable "table_settings" {
  description = "Settings for the DynamoDB table"
  type = object({
    name = string
    partition_key = string
    sort_key = string
    ttl = object({
      enabled = bool
      attribute_name = string
    })
  })
}
