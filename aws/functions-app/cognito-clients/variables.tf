variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = bool
  })
}

variable "clients_settings" {
  description = "Settings to configure identity clients for the API"
  type = map(object({
    purpose = string
  }))
}
