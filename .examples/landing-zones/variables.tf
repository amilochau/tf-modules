variable "aws_provider_settings" {
  description = "Settings to configure the AWS provider"
  type = object({
    region = optional(string, "eu-west-3")
  })
  default = {}
}
