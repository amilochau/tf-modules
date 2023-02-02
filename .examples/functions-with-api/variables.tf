variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name  = string
    host_name         = string
  })
  default = {
    application_name  = "sample"
    host_name         = "default"
  }
}

variable "aws_provider_settings" {
  description = "Settings to configure the AWS provider"
  type = object({
    profile = optional(string, "default")
    region  = optional(string, "eu-west-3")
  })
  default = {}
}
