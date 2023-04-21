module "conventions" {
  source      = "../../../../shared/conventions"
  conventions = var.conventions
}

data "aws_caller_identity" "caller_identity" {}

data "aws_iam_policy_document" "lambda_iam_policy_document" {

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

  // DynamoDB tables
  dynamic "statement" {
    for_each = { for k, v in var.accesses_settings.dynamodb_table_arns: k => v }
    content {
      actions = [
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      resources = [
        statement.value,
        "${statement.value}/*"
      ]
      effect = "Allow"
    }
  }
  
  // SES identities
  dynamic "statement" {
    for_each = { for k, v in var.accesses_settings.ses_domain_identity_arns: k => v }
    content {
    actions = [
      "ses:SendTemplatedEmail"
    ]
    resources = [
      "*" # Allow to send emails to any email address
    ]
    effect = "Allow"
    }
  }
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name        = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-lambda-${var.function_settings.function_key}"
  description = "IAM policy for a lambda"
  policy      = data.aws_iam_policy_document.lambda_iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachment" {
  role       = var.function_settings.role_name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}
