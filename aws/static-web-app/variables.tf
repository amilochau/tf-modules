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

variable "client_settings" {
  description = "Settings to configure the client"
  type = object({
    client_type = optional(string, "spa")
    package_source_file   = string
    s3_bucket_name_suffix = optional(string, "")
    domains = optional(object({
      zone_name                 = string
      domain_name               = string
      subject_alternative_names = optional(list(string), [])
    }), null)
  })

  validation {
    condition     = var.client_settings.s3_bucket_name_suffix == "" || length(var.client_settings.s3_bucket_name_suffix) <= 8 && can(regex("^[a-z0-9]+$", var.client_settings.s3_bucket_name_suffix))
    error_message = "S3 bucket name suffix must use less than 8 characters, only lowercase letters and numbers"
  }

  validation {
    condition     = contains(["spa", "ssg"], var.client_settings.client_type)
    error_message = "Client type must be 'spa' or 'ssg'"
  }
}

variable "api_settings" {
  description = "Settings to configure the integration with a previously deployed API"
  type = object({
    domain_name     = string
    origin_path     = string
    allowed_origins = optional(list(string), [])
  })
  default = null
}
