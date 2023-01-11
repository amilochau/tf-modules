variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
}

variable "settings" {
  description = "Settings to configuration the Lambda"
  type = object({
    memory_size_mb = number
    timeout_s      = number
    runtime        = string
    architecture   = string
    deployment_file_path = string
    handler              = string
  })
}
