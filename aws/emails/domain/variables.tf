variable "domain" {
  description = "Domain to configure"
  type = string
}

variable "mail_from_subdomain" {
  description = "Subdomain (relative to the domain) used for MAIL FROM"
  type = string
}

variable "notifications_sns_topic_arn" {
  description = "ARN of the SNS topic to be used for notifications"
  type = string
}
