variable "domain" {
  description = "Domain to configure"
  type        = string
}

variable "configuration_set_name" {
  description = "Name of the default configuration set to use"
  type        = string
}

variable "mail_from_subdomain" {
  description = "Subdomain (relative to the domain) used for MAIL FROM"
  type        = string
}
