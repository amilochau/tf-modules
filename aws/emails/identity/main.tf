data "aws_region" "current" {}

data "aws_route53_zone" "route53_zone" {
  name = var.zone_name
}

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

# ===== DNS RECORDS =====

resource "aws_route53_record" "route53_record_mx_spf_verification" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "${var.mail_from_subdomain}.${aws_sesv2_email_identity.identity.email_identity}"
  type    = "MX"
  ttl     = 3600
  records = [
    "10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"
  ]
}

resource "aws_route53_record" "route53_record_txt_spf_verification" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "${var.mail_from_subdomain}.${aws_sesv2_email_identity.identity.email_identity}"
  type    = "TXT"
  ttl     = 3600
  records = [
    "v=spf1 include:amazonses.com ~all"
  ]
}

resource "aws_route53_record" "route53_record_txt_dmarc_verification" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "_dmarc.${aws_sesv2_email_identity.identity.email_identity}"
  type    = "TXT"
  ttl     = 3600
  records = [
    "v=DMARC1;p=none" # see https://www.rfc-editor.org/rfc/rfc7489#section-6.3
  ]
}

resource "aws_route53_record" "route53_record_cname_dkim_tokens" {
  for_each = { for k, v in flatten([for v in aws_sesv2_email_identity.identity.dkim_signing_attributes : v.tokens]) : k => v }

  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "${each.value}._domainkey.${aws_sesv2_email_identity.identity.email_identity}"
  type    = "CNAME"
  ttl     = 3600
  records = [
    "${each.value}.dkim.amazonses.com"
  ]
}
