output "sns_topic_notifications" {
  description = "SNS topic name for SES notifications"
  value       = aws_sns_topic.notifications_topic.name
}
