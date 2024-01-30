variable "context" {
  description = "Context to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = bool
  })
}

variable "cognito_user_pool_name" {
  description = "Name of the Cognito user pool"
  type        = string
}

variable "clients_settings" {
  description = "Settings to configure identity clients for the API"
  type = map(object({
    purpose                 = string
    disable_users_migration = bool
  }))
}
