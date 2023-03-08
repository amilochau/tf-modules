variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
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

variable "client_settings" {
  description = "Settings to configure the client"
  type = object({
    package_source_file        = string
    default_root_object = optional(string, "index.html")
  })
}

variable "api_settings" {
  description = "Settings to configure the integration with a previously deployed API"
  type = object({
    domain_name = string
    origin_path = string
    allowed_origins = optional(list(string), [])
  })
  default = null
}
