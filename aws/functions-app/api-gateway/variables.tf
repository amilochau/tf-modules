variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
}

variable "functions_outputs" {
  description = "Outputs from the previously created lambda functions"
  type = object({
    function_name = string
    invoke_arn = string
  })
}

variable "cognito_outputs" {
  description = "Outputs from the previously created Cognito user pool and Cognito clients"
  type = object({
    user_pool_id = string
    client_ids = list(string)
  })
}
