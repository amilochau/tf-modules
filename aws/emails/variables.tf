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

variable "domains" {
  description = "Domains to use as emails identity"
  type = map(object({
    mail_from_subdomain = string
  }))
}

variable "templates" {
  description = "Email templates to use in SES"
  type = map(object({
    subject = string
    html    = string
    text    = string
  }))

  validation {
    condition = alltrue([
      for v in var.templates : can(regex("{{unsubscribe_url}}", v.html)) && can(regex("{{unsubscribe_url}}", v.text))
    ])
    error_message = "Template data are required."
  }
}
