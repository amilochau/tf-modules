variable "context" {
  description = "Context to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = bool
  })
}

variable "function_name" {
  description = "Name of the already deployed Lambda function"
  type        = string
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
  })
}
