variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
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
