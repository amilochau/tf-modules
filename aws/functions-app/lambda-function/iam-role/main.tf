module "conventions" {
  source      = "../../../../shared/conventions"
  conventions = var.conventions
}

data "aws_caller_identity" "caller_identity" {}

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
    # Using 'AWS:SourceAccount' make deployment fail
    effect = "Allow"
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  name               = "${module.conventions.aws_naming_conventions.iam_role_name_prefix}-lambda-${var.function_settings.function_key}"
  description        = "IAM role used by the lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_policy_document_role.json
}

# ===== POLICY =====

locals {
  dynamodb_statement_resources            = flatten([for k, v in var.accesses_settings.dynamodb_table_arns : [v, "${v}/*"]])
  ses_domain_identity_statement_resources = length(var.accesses_settings.ses_domain_identity_arns) > 0 ? ["*"] : [] # Allow to send emails to any email address
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
    /*condition { # @todo to test
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values = [
        data.aws_caller_identity.caller_identity.account_id
      ]
    }*/
    effect = "Allow"
  }

  // DynamoDB tables
  dynamic "statement" {
    for_each = length(local.dynamodb_statement_resources) > 0 ? [1] : []
    content {
      actions = [
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      resources = local.dynamodb_statement_resources
      /*condition {
        test     = "StringEquals"
        variable = "AWS:SourceAccount"
        values = [
          data.aws_caller_identity.caller_identity.account_id
        ]
      }*/
      effect = "Allow"
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
      /*condition {
        test     = "StringEquals"
        variable = "AWS:SourceAccount"
        values = [
          data.aws_caller_identity.caller_identity.account_id
        ]
      }*/
      effect = "Allow"
    }
  }
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name        = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-lambda-${var.function_settings.function_key}"
  description = "IAM policy for a lambda"
  policy      = data.aws_iam_policy_document.lambda_iam_policy_document_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachment" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
