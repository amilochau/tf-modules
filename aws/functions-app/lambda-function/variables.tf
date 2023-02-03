variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
  })
}

variable "settings" {
  description = "Settings to configuration the Lambda"
  type = object({
    runtime               = string
    architecture          = string
    function_key          = string
    memory_size_mb        = number
    timeout_s             = number
    deployment_file_path  = string
    handler               = string
    environment_variables = map(string)
    http_trigger = object({
      method      = string
      route       = string
      anonymous   = bool
      enable_cors = bool
    })
    sns_trigger = object({
      topic_name = string
    })
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
    table_arn  = string
  }))
}
