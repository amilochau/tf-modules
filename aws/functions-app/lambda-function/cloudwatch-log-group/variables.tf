variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = bool
  })
}

variable "function_settings" {
  description = "Settings of the previously deployed Lambda Function"
  type        = object({
    function_key = string
    function_name = string
  })
}
