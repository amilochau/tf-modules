resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  function_name                      = var.function_settings.function_name
  event_source_arn                   = var.dynamodb_stream_settings.stream_arn
  starting_position                  = "LATEST"
  batch_size                         = 10
  bisect_batch_on_function_error     = true
  maximum_batching_window_in_seconds = 10
  maximum_retry_attempts             = 10
  function_response_types = [
    "ReportBatchItemFailures"
  ]

  dynamic "filter_criteria" {
    for_each = length(var.dynamodb_stream_settings.filter_criteria_patterns) > 0 ? [1] : []
    content {
      dynamic "filter" {
        for_each = { for k, v in var.dynamodb_stream_settings.filter_criteria_patterns : k => v }
        content {
          pattern = filter.value
        }
      }
    }
  }
}
