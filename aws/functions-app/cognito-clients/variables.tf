variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
}

variable "clients" {
  description = "Settings to configure identity clients for the API"
  type = map(object({
    purpose = string
  }))
}
