output "domain_records" {
  description = "DNS records to add, so that domains can be verified"
  value = [
    for v in module.domains : v.domain_records
  ]
}

output "sns_topic_notifications" {
  description = "SNS topic name for SES notifications"
  value = aws_sns_topic.notifications_topic.name
}
