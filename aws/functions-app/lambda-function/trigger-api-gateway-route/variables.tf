variable "function_settings" {
  description = "Settings to use for the API Gateway route"
  type = object({
    invoke_arn    = string
  })
}

variable "api_gateway_settings" {
  description = "Settings for the previously deployed API Gateway v2"
  type = object({
    api_id            = string
    api_execution_arn = string
    authorizer_id     = string
    method        = string
    route         = string
    anonymous     = bool
    enable_cors   = bool
  })
}
