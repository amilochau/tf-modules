variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = bool
  })
}
