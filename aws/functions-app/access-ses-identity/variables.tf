variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
  })
}

variable "ses_domain" {
  description = "Domain of the SES identity to use"
  type = string
}
