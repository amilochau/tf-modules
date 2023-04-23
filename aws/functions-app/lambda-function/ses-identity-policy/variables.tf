variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = bool
  })
}

variable "ses_domain" {
  description = "Domain of the SES identity to use"
  type        = string
}

variable "function_arn" {
  description = "ARN of the previously deployed Lambda Function"
  type        = string
}
