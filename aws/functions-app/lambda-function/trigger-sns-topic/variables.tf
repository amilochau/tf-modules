variable "function_settings" {
  description = "Settings to use for the SNS topic subscription"
  type = object({
    function_name = string
    function_arn  = string
  })
}

variable "sns_settings" {
  description = "Settings for the previously deployed SNS"
  type = object({
    description = string
    topic_name = string
  })
}
