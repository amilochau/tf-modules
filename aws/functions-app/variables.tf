variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
}

variable lambda_settings {
  description = "Settings to configuration the Lambda"
  type = object({
    memory_size = number
  })

  validation {
    condition = var.lambda_settings.memory_size >= 128
    error_message = "Memory size must be greater or equal than 128 MB"
  }

  validation {
    condition = var.lambda_settings.memory_size <= 1024
    error_message = "Memory size must be lower or equal than 1024 MB"
  }
}
