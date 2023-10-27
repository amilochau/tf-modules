variable "function_settings" {
  description = "Settings to use for the SNS topic subscription"
  type = object({
    function_name = string
  })
}

variable "dynamodb_stream_settings" {
  description = "Settings for the previously deployed DynamoDB stream"
  type = object({
    description                        = string
    stream_arn                         = string
    filter_criteria_patterns           = list(string)
    batch_size                         = number
    maximum_batching_window_in_seconds = number
    maximum_retry_attempts             = number
  })
}
