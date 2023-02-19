variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
  })
}

variable "function_settings" {
  description = "Settings to configuration the Lambda"
  type = object({
    runtime               = string
    architecture          = string
    function_key          = string
    memory_size_mb        = number
    timeout_s             = number
    deployment_source_file_path = string
    deployment_file_path  = string
    handler               = string
    environment_variables = map(string)
  })
}

variable "triggers_settings" {
  description = "Settings for the triggers in front of the Function"
  type = object({
    api_gateway_routes = list(object({
      api_id            = string
      api_execution_arn = string
      authorizer_id     = string
      method      = string
      route       = string
      anonymous   = bool
      enable_cors = bool
    }))
    sns_topics = list(object({
      topic_name = string
    }))
  })
}

variable "accesses_settings" {
  description = "Settings for the accesses to grant to the Function"
  type = object({
    iam_policy_arns = list(string)
    ses_domains = list(string)
  })
}
