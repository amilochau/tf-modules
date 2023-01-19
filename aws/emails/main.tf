terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.50, < 5.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

module "environment" {
  source      = "../../shared/environment"
  conventions = var.conventions
}

module "conventions" {
  source      = "../../shared/conventions"
  conventions = var.conventions
}

data "aws_region" "current" {}

resource "aws_ses_domain_identity" "domain_identity" {
  count = var.domain != null ? 1 : 0
  domain = var.domain
}

resource "aws_ses_domain_identity_verification" "example_verification" {
  count = var.domain != null ? 1 : 0
  domain = aws_ses_domain_identity.domain_identity[0].domain
}

resource "aws_ses_domain_dkim" "domain_dkim" {
  count = var.domain != null ? 1 : 0
  depends_on = [
    aws_ses_domain_identity_verification.example_verification[0]
  ]
  domain = var.domain != null ? aws_ses_domain_identity.domain_identity[0].domain : null
}

resource "aws_ses_domain_mail_from" "domain_mail_from" {
  count = var.domain != null && var.mail_from_subdomain != null ? 1 : 0
  depends_on = [
    aws_ses_domain_identity_verification.example_verification[0]
  ]
  domain = aws_ses_domain_identity.domain_identity[0].domain
  mail_from_domain = "${var.mail_from_subdomain}.${aws_ses_domain_identity.domain_identity[0].domain}"
  behavior_on_mx_failure = "RejectMessage"
}

resource "aws_ses_template" "templates" {
  for_each = var.templates

  name = "${module.conventions.aws_naming_conventions.ses_template_name_prefix}-${each.key}"
  subject = each.value.subject
  html = each.value.html
  text = each.value.text
}
