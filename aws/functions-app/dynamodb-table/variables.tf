variable "context" {
  description = "Context to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = bool
  })
}

variable "table_settings" {
  description = "Settings for the DynamoDB table"
  type = object({
    name          = string
    partition_key = string
    sort_key      = string
    attributes = map(object({
      type = string
    }))
    ttl = object({
      enabled        = bool
      attribute_name = string
    })
    global_secondary_indexes = map(object({
      partition_key      = string
      sort_key           = string
      non_key_attributes = list(string)
    }))
    enable_stream           = bool
    max_read_request_units  = number
    max_write_request_units = number
  })
}
