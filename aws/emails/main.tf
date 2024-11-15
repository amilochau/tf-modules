terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
      configuration_aliases = [
        aws.infrastructure,
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
}

module "environment" {
  source  = "../../shared/environment"
  context = var.context
}

module "conventions" {
  source  = "../../shared/conventions"
  context = var.context
}

# ===== SNS topic =====

resource "aws_sns_topic" "notifications_topic" {
  name           = "${module.conventions.aws_naming_conventions.sns_topic_name_prefix}-notifications"
  tracing_config = "Active"

  provider = aws.workloads
}

# ===== SES resources =====

resource "aws_ses_template" "templates" {
  for_each = var.templates

  name    = "${module.conventions.aws_naming_conventions.ses_template_name_prefix}-${each.key}"
  subject = each.value.subject
  html    = each.value.html
  text    = each.value.text

  provider = aws.workloads
}

resource "aws_sesv2_configuration_set" "configuration_set" {
  configuration_set_name = module.conventions.aws_naming_conventions.ses_configuration_set_name

  sending_options {
    sending_enabled = true
  }
  reputation_options {
    reputation_metrics_enabled = true
  }

  provider = aws.workloads
}

resource "aws_sesv2_configuration_set_event_destination" "configuration_set_event_destination" {
  depends_on = [
    aws_sns_topic_policy.notification_topic_policy // We need to authorize SES to publish to SNS first
  ]
  configuration_set_name = aws_sesv2_configuration_set.configuration_set.configuration_set_name
  event_destination_name = aws_sns_topic.notifications_topic.name

  event_destination {
    sns_destination {
      topic_arn = aws_sns_topic.notifications_topic.arn
    }

    enabled              = true
    matching_event_types = ["BOUNCE", "COMPLAINT", "DELIVERY_DELAY", "REJECT", "RENDERING_FAILURE", "SUBSCRIPTION"]
  }

  provider = aws.workloads
}

module "identities" {
  for_each = var.domains
  source   = "./identity"

  domain                 = each.key
  zone_name              = each.value.zone_name
  configuration_set_name = aws_sesv2_configuration_set.configuration_set.configuration_set_name
  mail_from_subdomain    = each.value.mail_from_subdomain

  providers = {
    aws.infrastructure = aws.infrastructure
    aws.workloads      = aws.workloads
  }
}

# ===== SES identities to SNS topic =====

data "aws_caller_identity" "caller_identity" {
  provider = aws.workloads
}

data "aws_iam_policy_document" "sns_topic_iam_policy_document" {
  policy_id = "notification-policy"

  statement {
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.notifications_topic.arn,
    ]
    principals {
      type = "Service"
      identifiers = [
        "ses.amazonaws.com"
      ]
    }
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
        aws_sesv2_configuration_set.configuration_set.arn
      ]
    }
    effect = "Allow"
  }
}

resource "aws_sns_topic_policy" "notification_topic_policy" {
  arn    = aws_sns_topic.notifications_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_iam_policy_document.json

  provider = aws.workloads
}
