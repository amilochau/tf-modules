variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = bool
  })
}

variable "distribution_settings" {
  description = "Settings to configure the CloudFront distribution"
  type = object({
    default_root_object = string
    origin_api = object({
      domain_name     = string
      origin_path     = string
      allowed_origins = list(string)
    })
    origin_client = object({
      domain_name = string
    })
    domains = object({
      alternate_domain_names = list(string)
      certificate_arn = string
    })
  })
}
