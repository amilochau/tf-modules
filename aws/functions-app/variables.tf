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

variable "lambda_settings" {
  description = "Settings to configuration the Lambda"
  type = object({
    runtime      = string
    architecture = string

    functions = map(object({
      memory_size_mb              = optional(number, 512)
      timeout_s                   = optional(number, 10)
      deployment_source_file_path = optional(string, "")
      deployment_file_path        = string
      handler                     = string
      environment_variables       = optional(map(string), {})
      minimum_log_level           = optional(string, "WARN")
      http_triggers = optional(list(object({
        description        = optional(string, null)
        method             = string
        route              = string
        request_parameters = optional(map(string), null)
        anonymous          = optional(bool, false)
        enable_cors        = optional(bool, false)
      })), [])
      sns_triggers = optional(list(object({
        description = optional(string, null)
        topic_arn   = string
      })), [])
      scheduler_triggers = optional(list(object({
        description         = optional(string, null)
        schedule_expression = string
        enabled             = optional(bool, true)
      })), [])
      dynamodb_stream_triggers = optional(list(object({
        description                        = optional(string, null)
        table_name                         = string
        filter_criteria_patterns           = optional(list(string), [])
        batch_size                         = optional(number, 10)
        maximum_batching_window_in_seconds = optional(number, 10)
        maximum_retry_attempts             = optional(number, 10)
      })), [])
      ses_accesses = optional(list(object({
        domain = string
      })), [])
      lambda_accesses = optional(list(object({
        arn = string
      })), [])
      dynamodb_table_accesses = optional(list(object({
        arn = string
      })), [])
      sns_topic_accesses = optional(list(object({
        arn = string
      })), [])
      cognito_userpools_access = optional(bool, false)
    }))
    existing_functions = optional(map(object({
      http_triggers = optional(list(object({
        description        = optional(string, null)
        method             = string
        route              = string
        request_parameters = optional(map(string), null)
        anonymous          = optional(bool, false)
        enable_cors        = optional(bool, false)
      })), [])
    })), {})
  })

  validation {
    condition     = contains(["provided.al2", "provided.al2023", "nodejs18.x"], var.lambda_settings.runtime)
    error_message = "Runtime must be 'provided.al2', 'provided.al2023' or 'nodejs18.x'"
  }

  validation {
    condition     = contains(["x86_64", "arm64"], var.lambda_settings.architecture)
    error_message = "Architecture must be 'x86_64' or 'arm64'"
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
      for v in var.lambda_settings.functions : alltrue([
        for v2 in v.http_triggers : contains(["ANY", "GET", "POST", "PUT", "PATCH", "HEAD", "DELETE"], v2.method)
      ]) if length(v.http_triggers) > 0
    ])
    error_message = "Function HTTP trigger methods must be one of ANY, GET, POST, PUT, PATCH, HEAD, DELETE"
  }

  validation {
    condition = alltrue([
      for v in var.lambda_settings.functions : v.timeout_s >= 1 && v.timeout_s <= 900
    ])
    error_message = "Timeout must be between 1 second and 900 seconds"
  }

  validation {
    condition = alltrue([
      for v in var.lambda_settings.functions : alltrue([
        for v2 in v.dynamodb_stream_triggers : length(v2.filter_criteria_patterns) <= 5
      ]) if length(v.dynamodb_stream_triggers) > 0
    ])
    error_message = "DynamoDB stream trigger can only include up to 5 filter criteria patterns"
  }

  validation {
    condition = alltrue([
      for v in var.lambda_settings.functions : contains(["DEBUG", "INFO", "WARN"], v.minimum_log_level)
    ])
    error_message = "Minimum log level must be 'DEBUG', 'INFO' or 'WARN'"
  }
}

variable "cognito_user_pool_id" {
  description = "Id of the Cognito user pool"
  type        = string
  default     = null
}

variable "cognito_clients_settings" {
  description = "Settings to configure identity clients for the API"
  type = map(object({
    purpose                 = string
    disable_users_migration = optional(bool, false)
  }))
  default = {}
}

variable "dynamodb_tables_settings" {
  description = "Settings to configure DynamoDB tables for the API"
  type = map(object({
    partition_key = string
    sort_key      = optional(string, null)
    attributes = optional(map(object({
      type = string
    })), {})
    ttl = optional(object({
      enabled        = bool
      attribute_name = optional(string, "ttl")
      }), {
      enabled = false
    })
    global_secondary_indexes = optional(map(object({
      partition_key      = string
      sort_key           = string
      non_key_attributes = list(string)
    })), {})
    enable_stream = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.dynamodb_tables_settings : can(regex("^[a-z0-9_]+$", k))
    ])
    error_message = "Table key must use only lowercase letters, numbers and underscores ('_')"
  }
}

variable "sns_topics_settings" {
  description = "Settings to configure SNS topics for the API"
  type = map(object({
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.sns_topics_settings : can(regex("^[a-z0-9_]+$", k))
    ])
    error_message = "SNS topic key must use only lowercase letters, numbers and underscores ('_')"
  }
}
