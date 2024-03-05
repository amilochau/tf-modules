variable "context" {
  description = "Context to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = bool
  })
}

variable "topic_settings" {
  description = "Settings for the SNS topic"
  type = object({
    name = string
  })
}
