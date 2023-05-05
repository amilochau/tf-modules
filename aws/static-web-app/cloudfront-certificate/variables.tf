variable "certificate_settings" {
  description = "Settings for the CloudFront certificate to deploy"
  type = object({
    zone_name           = string
    domain_name = string
    subject_alternative_names = list(string)
  })
}