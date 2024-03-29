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
