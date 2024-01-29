variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = optional(bool, false)
  })
  default = {
    organization_name = "exmpl"
    application_name  = "sample"
    host_name         = "default"
    temporary         = true
  }
}

variable "assume_roles" {
  description = "Roles to be assumed"
  type = object({
    sandbox = optional(string, "arn:aws:iam::381492034295:role/administrator-access")
  })
}

variable "aws_provider_settings" {
  description = "Settings to configure the AWS provider"
  type = object({
    region = optional(string, "eu-west-3")
  })
  default = {}
}
