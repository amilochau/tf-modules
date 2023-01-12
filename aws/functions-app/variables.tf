variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })

  validation {
    condition = length(var.conventions.organization_name) > 2 && length(var.conventions.organization_name) < 8 && can(regex("^[a-z]+$", var.conventions.organization_name))
    error_message = "Organization name must use between 2 and 8 characters, only with lowercase letters"
  }

  validation {
    condition = length(var.conventions.application_name) > 2 && length(var.conventions.application_name) < 12 && can(regex("^[a-z]+$", var.conventions.organization_name))
    error_message = "Application name must use between 2 and 12 characters, only with lowercase letters"
  }

  validation {
    condition = length(var.conventions.host_name) > 3 && length(var.conventions.host_name) < 8 && can(regex("^[a-z0-9]+$", var.conventions.organization_name))
    error_message = "Host name must use between 2 and 8 characters, only with lowercase letters and numbers"
  }
}

variable "lambda_settings" {
  description = "Settings to configuration the Lambda"
  type = object({
    memory_size_mb = number
    timeout_s      = optional(number, 10)
    runtime        = string
    architecture   = string

    expose_apis          = bool
    deployment_file_path = string
    handler              = string
  })

  validation {
    condition     = var.lambda_settings.memory_size_mb >= 128 && var.lambda_settings.memory_size_mb <= 1024
    error_message = "Memory size must be between 128 MB and 1024 MB"
  }

  validation {
    condition     = contains(["provided.al2", "nodejs18.x"], var.lambda_settings.runtime)
    error_message = "Runtime must be 'provided.al2' or 'nodejs18.x'"
  }

  validation {
    condition     = contains(["x86_64", "arm64"], var.lambda_settings.architecture)
    error_message = "Architecture must be 'x86_64' or 'arm64'"
  }
}

variable "clients" {
  description = "Settings to configure identity clients for the API"
  type = map(object({
    purpose = string
  }))
  default = {}
}
