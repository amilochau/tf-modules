data "aws_sns_topic" "sns_topic" {
  name = var.sns_settings.topic_name
}

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = data.aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = var.function_settings.function_arn
}

resource "aws_lambda_permission" "sns_topic_permission" {
  statement_id  = "AllowExecutionFromSnsTopic-${var.sns_settings.topic_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.function_settings.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.sns_topic.arn
}
