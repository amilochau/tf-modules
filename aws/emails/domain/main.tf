data "aws_region" "current" {}

resource "aws_ses_domain_identity" "domain_identity" {
  domain = var.domain
}

resource "aws_ses_domain_identity_verification" "example_verification" {
  domain = aws_ses_domain_identity.domain_identity.domain
}

resource "aws_ses_domain_dkim" "domain_dkim" {
  depends_on = [
    aws_ses_domain_identity_verification.example_verification
  ]
  domain = aws_ses_domain_identity.domain_identity.domain
}

resource "aws_ses_domain_mail_from" "domain_mail_from" {
  depends_on = [
    aws_ses_domain_identity_verification.example_verification
  ]
  domain = aws_ses_domain_identity.domain_identity.domain
  mail_from_domain = "${var.mail_from_subdomain}.${aws_ses_domain_identity.domain_identity.domain}"
  behavior_on_mx_failure = "RejectMessage"
}

resource "aws_ses_identity_notification_topic" "identity_notification_topic" {
  identity = aws_ses_domain_identity.domain_identity.domain
  topic_arn = var.notifications_sns_topic_arn
  notification_type = "Delivery"
}
