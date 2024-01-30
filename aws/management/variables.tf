variable "context" {
  description = "Context to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = optional(bool, false)
  })

  validation {
    condition     = length(var.context.organization_name) >= 3 && length(var.context.organization_name) <= 5 && can(regex("^[a-z]+$", var.context.organization_name))
    error_message = "Organization name must use between 3 and 5 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.context.application_name) >= 2 && length(var.context.application_name) <= 12 && can(regex("^[a-z]+$", var.context.application_name))
    error_message = "Application name must use between 2 and 12 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.context.host_name) >= 3 && length(var.context.host_name) <= 8 && can(regex("^[a-z0-9]+$", var.context.host_name))
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

variable "account_primary_contact" {
  description = "Account primary contact"
  type = object({
    full_name          = string
    company_name       = optional(string, null)
    address_line_1     = string
    postal_code        = string
    city               = string
    state_or_region    = optional(string, null)
    district_or_county = optional(string, null)
    country_code       = string
    phone_number       = string
    website_url        = optional(string, null)
  })
  default = null
}

variable "budgets" {
  description = "Budgets"
  type = map(object({
    limit_amount_usd = string
    notifications = list(object({
      threshold_percent = number
      forecast          = optional(bool, false)
      email_addresses   = list(string)
    }))
  }))
  default = {}
}
