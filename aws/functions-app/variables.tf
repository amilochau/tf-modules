variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name  = string
    host_name         = string
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

variable "lambda_settings" {
  description = "Settings to configuration the Lambda"
  type = object({
    runtime              = string
    architecture         = string

    functions = map(object({
      memory_size_mb = optional(number, 128)
      timeout_s      = optional(number, 10)
      deployment_file_path = string
      handler        = string
      environment_variables = optional(map(string), {})
      http_trigger = optional(object({
        method      = string
        route       = string
        anonymous   = optional(bool, false)
        enable_cors = optional(bool, false)
      }), null)
      sns_trigger = optional(object({
        topic_name = string
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

  validation {
    condition = alltrue([
      for v in var.lambda_settings.functions :
        v.http_trigger != null && v.sns_trigger == null ||
        v.http_trigger == null && v.sns_trigger != null ||
        v.http_trigger == null && v.sns_trigger == null
    ])
    error_message = "At most one trigger can be set for a function"
  }
}

variable "cognito_clients_settings" {
  description = "Settings to configure identity clients for the API"
  type = map(object({
    purpose = string
  }))
  default = {}
}

variable "dynamodb_tables_settings" {
  description = "Settings to configure DynamoDB tables for the API"
  type = map(object({
    partition_key = string
    sort_key = optional(string, null)
    attributes = optional(map(object({
      type = string
    })), {})
    ttl = optional(object({
      enabled = bool
      attribute_name = optional(string, "ttl")
    }), {
      enabled = false
    })
    global_secondary_indexes = optional(map(object({
      partition_key = string
      sort_key = string
      non_key_attributes = list(string)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.dynamodb_tables_settings : can(regex("^[a-z0-9_]+$", k))
    ])
    error_message = "Table key must use only lowercase letters, numbers and underscores ('_')"
  }
}
