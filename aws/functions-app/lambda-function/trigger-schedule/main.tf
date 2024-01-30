terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

module "conventions" {
  source  = "../../../../shared/conventions"
  context = var.context
}

data "aws_caller_identity" "caller_identity" {
  provider = aws.workloads
}

# ===== ROLE ASSUMED BY SCHEDULER =====

data "aws_iam_policy_document" "schedule_iam_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "scheduler.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values = [
        data.aws_caller_identity.caller_identity.account_id
      ]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "schedule_iam_role" {
  name               = "${module.conventions.aws_naming_conventions.iam_role_name_prefix}-schedule-${var.function_settings.function_key}"
  description        = "IAM role used by schedule"
  assume_role_policy = data.aws_iam_policy_document.schedule_iam_policy_document.json

  provider = aws.workloads
}

# ===== POLICY GIVEN TO SCHEDULER ROLE TO INVOKE FUNCTION =====

data "aws_iam_policy_document" "schedule_iam_policy_document_lambda" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      var.function_settings.function_arn,
      "${var.function_settings.function_arn}:*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "schedule_iam_policy_lambda" {
  name        = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-schedule-fn-${var.function_settings.function_key}"
  description = "IAM policy for invoking a lambda function from a Schedule"
  policy      = data.aws_iam_policy_document.schedule_iam_policy_document_lambda.json

  provider = aws.workloads
}

resource "aws_iam_role_policy_attachment" "schedule_iam_role_policy_attachment" {
  role       = aws_iam_role.schedule_iam_role.name
  policy_arn = aws_iam_policy.schedule_iam_policy_lambda.arn

  provider = aws.workloads
}

# ===== SCHEDULE =====

resource "aws_scheduler_schedule" "schedule" {
  for_each = { for k, v in var.schedule_settings.schedules : k => v }

  name       = "${module.conventions.aws_naming_conventions.eventbridge_schedule_name_prefix}-${var.function_settings.function_key}-${each.key}"
  group_name = var.schedule_settings.schedule_group_name

  description         = each.value.description
  schedule_expression = each.value.schedule_expression
  state               = each.value.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = module.conventions.aws_format_conventions.eventbridge_schedule_flexible_window_min
  }

  target {
    arn      = var.function_settings.function_arn
    role_arn = aws_iam_role.schedule_iam_role.arn

    retry_policy {
      maximum_retry_attempts       = module.conventions.aws_format_conventions.eventbridge_schedule_retries
      maximum_event_age_in_seconds = module.conventions.aws_format_conventions.eventbridge_schedule_event_age_sec
    }
  }

  provider = aws.workloads
}
