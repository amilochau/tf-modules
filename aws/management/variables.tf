variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = optional(bool, false)
  })

  validation {
    condition     = length(var.conventions.application_name) >= 2 && length(var.conventions.application_name) <= 12 && can(regex("^[a-z]+$", var.conventions.application_name))
    error_message = "Application name must use between 2 and 12 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.conventions.host_name) >= 3 && length(var.conventions.host_name) <= 8 && can(regex("^[a-z0-9]+$", var.conventions.host_name))
    error_message = "Host name must use between 2 and 8 characters, only lowercase letters and numbers"
  }
}

variable "region_type" {
  description = "Type of AWS region"
  type        = string

  validation {
    condition     = var.region_type == "Primary" || var.region_type == "Secondary"
    error_message = "Type must be 'Primary' or 'Secondary'"
  }
}

variable "domains" {
  description = "Domains to manage"
  type = map(object({
    domain_description = optional(string, null)
    records = map(object({
      type        = string
      ttl_seconds = number
      records     = list(string)
    }))
  }))
  default = {}
}

variable "budgets" {
  description = "Budgets"
  type = map(object({
    limit_amount_usd = string
    notifications = list(object({
      threshould_percent = number
      forecast           = bool
      email_addresses    = list(string)
    }))
  }))
}
