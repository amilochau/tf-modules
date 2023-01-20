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

# ===== SNS topic =====

resource "aws_sns_topic" "notifications_topic" {
  name = "${module.conventions.aws_naming_conventions.sns_topic_name_prefix}-notifications"
}

# ===== SES resources =====

resource "aws_ses_template" "templates" {
  for_each = var.templates

  name = "${module.conventions.aws_naming_conventions.ses_template_name_prefix}-${each.key}"
  subject = each.value.subject
  html = each.value.html
  text = each.value.text
}

module "domains" {
  for_each = var.domains
  source = "./domain"

  domain = each.key
  mail_from_subdomain = each.value.mail_from_subdomain
  notifications_sns_topic_arn = aws_sns_topic.notifications_topic.arn
}

# ===== SES identities to SNS topic =====

data "aws_caller_identity" "caller_identity" {}

data "aws_iam_policy_document" "sns_topic_iam_policy_document" {
  policy_id = "notification-policy"

  statement {
    actions = [
      "sns:Publish",
    ]
    principals {
      type = "Service"
      identifiers = [
        "ses.amazonaws.com"
      ]
    }
    effect = "Allow"

    resources = [
      aws_sns_topic.notifications_topic.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"

      values = [
        data.aws_caller_identity.caller_identity.account_id
      ]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "AWS:SourceArn"

      values = [
        for v in module.domains : v.domain_identity_arn
      ]
    }
  }
}

resource "aws_sns_topic_policy" "notification_topic_policy" {
  arn = aws_sns_topic.notifications_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_iam_policy_document.json
}
