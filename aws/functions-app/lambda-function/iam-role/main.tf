terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.59.0, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.9.2, < 2.0.0"
}

module "conventions" {
  source  = "../../../../shared/conventions"
  context = var.context
}

data "aws_caller_identity" "caller_identity" {
  provider = aws.workloads
}

data "aws_iam_policy_document" "lambda_iam_policy_document_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  name               = "${module.conventions.aws_naming_conventions.iam_role_name_prefix}-fn-${var.function_settings.function_key}"
  description        = "IAM role used by the lambda function"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_policy_document_role.json

  provider = aws.workloads
}

# ===== POLICY =====

locals {
  dynamodb_tables_statement_resources     = flatten([for k, v in var.accesses_settings.dynamodb_table_arns : [v, "${v}/*"]])
  dynamodb_streams_statement_resources    = var.accesses_settings.dynamodb_stream_arns
  sns_topics_statement_resources          = var.accesses_settings.sns_topics_arns
  ses_domain_identity_statement_resources = length(var.accesses_settings.ses_domain_identity_arns) > 0 ? ["*"] : [] # Allow to send emails to any email address
  lambda_statement_resources              = var.accesses_settings.lambda_arns
}

data "aws_iam_policy_document" "lambda_iam_policy_document_policy" {

  // CloudWatch log group
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${var.accesses_settings.cloudwatch_log_group_arn}:*"
    ]
    effect = "Allow"
  }

  // X-Ray Daemon
  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }

  // DynamoDB tables
  dynamic "statement" {
    for_each = length(local.dynamodb_tables_statement_resources) > 0 ? [1] : []
    content {
      actions = [
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      resources = local.dynamodb_tables_statement_resources
      effect    = "Allow"
    }
  }

  // DynamoDB streams
  dynamic "statement" {
    for_each = length(local.dynamodb_streams_statement_resources) > 0 ? [1] : []
    content {
      actions = [
        "dynamodb:DescribeStream",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:ListStreams"
      ]
      resources = local.dynamodb_streams_statement_resources
      effect    = "Allow"
    }
  }

  // SNS topics
  dynamic "statement" {
    for_each = length(local.sns_topics_statement_resources) > 0 ? [1] : []
    content {
      actions = [
        "sns:Publish"
      ]
      resources = local.sns_topics_statement_resources
      effect    = "Allow"
    }
  }

  // SES identities
  dynamic "statement" {
    for_each = length(local.ses_domain_identity_statement_resources) > 0 ? [1] : []
    content {
      actions = [
        "ses:SendTemplatedEmail"
      ]
      resources = local.ses_domain_identity_statement_resources
      effect    = "Allow"
    }
  }

  // Lambda functions
  dynamic "statement" {
    for_each = length(local.lambda_statement_resources) > 0 ? [1] : []
    content {
      actions = [
        "lambda:InvokeFunction"
      ]
      resources = local.lambda_statement_resources
      effect    = "Allow"
    }
  }

  // Cognito user pools
  dynamic "statement" {
    for_each = var.accesses_settings.cognito_userpools_access ? [1] : []
    content {
      actions = [
        "cognito-idp:AdminUpdateUserAttributes"
      ]
      resources = [
        "*"
      ]
      effect = "Allow"
    }
  }
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name        = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-fn-${var.function_settings.function_key}"
  description = "IAM policy for a lambda function"
  policy      = data.aws_iam_policy_document.lambda_iam_policy_document_policy.json

  provider = aws.workloads
}

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachment" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn

  provider = aws.workloads
}
