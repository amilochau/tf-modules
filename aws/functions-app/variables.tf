variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
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
