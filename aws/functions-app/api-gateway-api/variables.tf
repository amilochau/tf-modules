variable "context" {
  description = "Context to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = bool
  })
}

variable "enable_authorizer" {
  description = "Whether to enable authorizer to be used by at least one route"
  type        = bool
}

variable "cognito_settings" {
  description = "Settings for the previously created Cognito user pool and Cognito clients"
  type = object({
    user_pool_id = string
    client_ids   = list(string)
  })
}
