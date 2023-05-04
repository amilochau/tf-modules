variable "domain_settings" {
  description = "Settings of the domain to deploy"
  type = object({
    domain_name = string
    domain_description = string
  })
}
