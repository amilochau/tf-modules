variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = optional(bool, false)
  })

  validation {
    condition     = length(var.conventions.organization_name) >= 3 && length(var.conventions.organization_name) <= 5 && can(regex("^[a-z]+$", var.conventions.organization_name))
    error_message = "Organization name must use between 3 and 5 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.conventions.application_name) >= 2 && length(var.conventions.application_name) <= 12 && can(regex("^[a-z]+$", var.conventions.application_name))
    error_message = "Application name must use between 2 and 12 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.conventions.host_name) >= 3 && length(var.conventions.host_name) <= 8 && can(regex("^[a-z0-9]+$", var.conventions.host_name))
    error_message = "Host name must use between 2 and 8 characters, only lowercase letters and numbers"
  }
}

variable "github_identity_provider_arn" {
  description = "ARN of the GitHub Identity provider"
  type        = string
}

variable "organization_name" {
  description = "The name of the GitHub organization"
  type        = string
}

variable "aws_accounts" {
  description = "AWS accounts to which allow access"
  type        = list(string)
  default     = []
}
