variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = optional(bool, false)
  })
  default = {
    application_name = "sample"
    host_name        = "default"
    temporary        = true
  }
}

variable "aws_provider_settings" {
  description = "Settings to configure the AWS provider"
  type = object({
    region  = optional(string, "eu-west-3")
  })
  default = {}
}
