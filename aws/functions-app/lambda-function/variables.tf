variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
}

variable "settings" {
  description = "Settings to configuration the Lambda"
  type = object({
    runtime              = string
    architecture         = string
    function_key         = string
    memory_size_mb       = number
    timeout_s            = number
    deployment_file_path = string
    handler              = string
    http_trigger = optional(object({
      method      = string
      route       = string
      anonymous   = bool
      enable_cors = bool
    }), null)
  })
}

variable "apigateway_settings" {
  description = "Settings for the previously deployed API Gateway v2"
  type = object({
    api_id            = string
    api_execution_arn = string
    authorizer_id     = string
  })
}

variable "dynamodb_settings" {
  description = "Settings for the previously deployed DynamoDB"
  type = map(object({
    table_name = string
    table_arn = string
  }))
}
