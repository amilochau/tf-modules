output "topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.sns_topic.name
}

output "topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.sns_topic.arn
}