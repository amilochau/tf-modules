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

resource "aws_ses_template" "templates" {
  for_each = var.templates

  name = "${module.conventions.aws_naming_conventions.ses_template_name_prefix}-${each.key}"
  subject = each.value.subject
  html = each.value.html
  text = each.value.text
}

resource "aws_sns_topic" "notifications_topic" {
  name = "${module.conventions.aws_naming_conventions.sns_topic_name_prefix}-notifications"
}

module "domains" {
  for_each = var.domains
  source = "./domain"

  domain = each.key
  mail_from_subdomain = each.value.mail_from_subdomain
  notifications_sns_topic_arn = aws_sns_topic.notifications_topic.arn
}
