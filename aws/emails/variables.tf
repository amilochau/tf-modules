variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })

  validation {
    condition     = length(var.conventions.organization_name) >= 2 && length(var.conventions.organization_name) <= 8 && can(regex("^[a-z]+$", var.conventions.organization_name))
    error_message = "Organization name must use between 2 and 8 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.conventions.application_name) >= 2 && length(var.conventions.application_name) <= 12 && can(regex("^[a-z]+$", var.conventions.organization_name))
    error_message = "Application name must use between 2 and 12 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.conventions.host_name) >= 3 && length(var.conventions.host_name) <= 8 && can(regex("^[a-z0-9]+$", var.conventions.organization_name))
    error_message = "Host name must use between 2 and 8 characters, only lowercase letters and numbers"
  }
}

variable "domain" {
  description = "Domain to use as emails identity"
  type = string
  default = null
}

variable "mail_from_subdomain" {
  description = "Subdomain to use for MAIL FROM authentication"
  type = string
  default = null
}

variable "templates" {
  description = "Email templates to use in SES"
  type = map(object({
    subject = string
    html = string
    text = string
  }))
}
