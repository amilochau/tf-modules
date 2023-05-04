variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = bool
  })
}

variable "domain_settings" {
  description = "Settings of the domain to deploy"
  type = object({
    domain_name        = string
    domain_description = string
    records = map(object({
      type        = string
      ttl_seconds = number
      records     = list(string)
    }))
  })
}
