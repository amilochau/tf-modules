variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = bool
  })
}

variable "function_settings" {
  description = "Settings of the Lambda Function"
  type = object({
    function_key = string
  })
}

variable "accesses_settings" {
  description = "Settings of the resources that the deployed Lambda should have access to"
  type = object({
    cloudwatch_log_group_arn = string
    dynamodb_table_arns      = list(string)
    ses_domain_identity_arns = list(string)
  })
}
