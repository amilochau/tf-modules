variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })

  validation {
    condition     = length(var.conventions.organization_name) > 2 && length(var.conventions.organization_name) < 8 && can(regex("^[a-z]+$", var.conventions.organization_name))
    error_message = "Organization name must use between 2 and 8 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.conventions.application_name) > 2 && length(var.conventions.application_name) < 12 && can(regex("^[a-z]+$", var.conventions.organization_name))
    error_message = "Application name must use between 2 and 12 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.conventions.host_name) > 3 && length(var.conventions.host_name) < 8 && can(regex("^[a-z0-9]+$", var.conventions.organization_name))
    error_message = "Host name must use between 2 and 8 characters, only lowercase letters and numbers"
  }
}

variable "lambda_settings" {
  description = "Settings to configuration the Lambda"
  type = object({
    runtime              = string
    architecture         = string
    deployment_file_path = string

    functions = map(object({
      memory_size_mb = optional(number, 128)
      timeout_s      = optional(number, 10)
      handler        = string
      http_trigger = optional(object({
        method      = string
        route       = string
        anonymous   = optional(bool, false)
        enable_cors = optional(bool, false)
      }), null)
    }))
  })

  validation {
    condition     = contains(["provided.al2", "nodejs18.x"], var.lambda_settings.runtime)
    error_message = "Runtime must be 'provided.al2' or 'nodejs18.x'"
  }

  validation {
    condition     = contains(["x86_64", "arm64"], var.lambda_settings.architecture)
    error_message = "Architecture must be 'x86_64' or 'arm64'"
  }

  validation {
    condition     = length(var.lambda_settings.functions) > 0
    error_message = "At least one function must be defined"
  }

  validation {
    condition = alltrue([
      for k, v in var.lambda_settings.functions : can(regex("^[a-z0-9-]+$", k))
    ])
    error_message = "Function key must use only lowercase letters, numbers and dashes ('-')"
  }

  validation {
    condition = alltrue([
      for v in var.lambda_settings.functions : v.memory_size_mb >= 128 && v.memory_size_mb <= 1024
    ])
    error_message = "Memory size must be between 128 MB and 1024 MB"
  }

  validation {
    condition = alltrue([
      for v in var.lambda_settings.functions : contains(["ANY", "GET", "POST", "PUT", "PATCH", "HEAD", "DELETE"], v.http_trigger.method) if v.http_trigger != null
    ])
    error_message = "Function HTTP trigger methods must be one of ANY, GET, POST, PUT, PATCH, HEAD, DELETE"
  }

  validation {
    condition = alltrue([
      for v in var.lambda_settings.functions : v.timeout_s >= 1 && v.timeout_s <= 900
    ])
    error_message = "Memory size must be between 1 second and 900 seconds"
  }
}

variable "clients" {
  description = "Settings to configure identity clients for the API"
  type = map(object({
    purpose = string
  }))
  default = {}
}
