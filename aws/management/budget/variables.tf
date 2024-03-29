variable "context" {
  description = "Context to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = bool
  })
}

variable "budget_settings" {
  description = "Settings of the budget to deploy"
  type = object({
    name             = string
    limit_amount_usd = string
    notifications = list(object({
      threshold_percent = number
      forecast          = bool
      email_addresses   = list(string)
    }))
  })
}
