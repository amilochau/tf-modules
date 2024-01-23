terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  function_name                      = var.function_settings.function_name
  event_source_arn                   = var.dynamodb_stream_settings.stream_arn
  starting_position                  = "LATEST"
  batch_size                         = var.dynamodb_stream_settings.batch_size
  bisect_batch_on_function_error     = true
  maximum_batching_window_in_seconds = var.dynamodb_stream_settings.maximum_batching_window_in_seconds
  maximum_retry_attempts             = var.dynamodb_stream_settings.maximum_retry_attempts
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

  provider = aws.workloads
}
