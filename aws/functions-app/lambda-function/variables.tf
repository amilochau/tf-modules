variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = bool
  })
}

variable "function_settings" {
  description = "Settings to configure the Lambda"
  type = object({
    runtime                     = string
    architecture                = string
    function_key                = string
    memory_size_mb              = number
    timeout_s                   = number
    deployment_source_file_path = optional(string, "")
    deployment_file_path        = string
    handler                     = string
    environment_variables       = map(string)
  })
}

variable "triggers_settings" {
  description = "Settings for the triggers in front of the Function"
  type = object({
    api_gateway_routes = list(object({
      description       = string
      api_id            = string
      api_execution_arn = string
      authorizer_id     = string
      method            = string
      route             = string
      anonymous         = bool
      enable_cors       = bool
    }))
    sns_topics = list(object({
      description = string
      topic_name  = string
    }))
    schedules = list(object({
      description         = string
      schedule_expression = string
      enabled             = bool
    }))
    dynamodb_streams = list(object({
      description                        = string
      stream_arn                         = string
      filter_criteria_patterns           = list(string)
      batch_size                         = number
      maximum_batching_window_in_seconds = number
      maximum_retry_attempts             = number
    }))
  })
}

variable "accesses_settings" {
  description = "Settings for the accesses to grant to the Function"
  type = object({
    ses_domains         = list(string)
    lambda_arns         = list(string)
    schedule_group_name = string
    dynamodb_table_arns = list(string)
  })
}
