data "aws_region" "current" {}

resource "aws_sesv2_email_identity" "identity" {
  email_identity         = var.domain
  configuration_set_name = var.configuration_set_name
}

resource "aws_sesv2_email_identity_feedback_attributes" "identity_feedback_attributes" {
  email_identity           = aws_sesv2_email_identity.identity.email_identity
  email_forwarding_enabled = false
}

resource "aws_sesv2_email_identity_mail_from_attributes" "identity_mail_from" {
  email_identity         = aws_sesv2_email_identity.identity.email_identity
  behavior_on_mx_failure = "REJECT_MESSAGE"
  mail_from_domain       = "${var.mail_from_subdomain}.${aws_sesv2_email_identity.identity.email_identity}"
}

# @todo add IAM?
