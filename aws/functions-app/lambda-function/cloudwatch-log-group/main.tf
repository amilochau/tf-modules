module "conventions" {
  source      = "../../../../shared/conventions"
  conventions = var.conventions
}

resource "aws_cloudwatch_log_group" "cloudwatch_log_group_lambda" {
  name              = "/aws/lambda/${var.function_settings.function_name}"
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days
  skip_destroy      = !var.conventions.temporary
}

# ===== IAM POLICY =====

data "aws_iam_policy_document" "iam_policy_document_cloudwatch_log_group" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.cloudwatch_log_group_lambda.arn}:*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "iam_policy_cloudwatch_log_group" {
  name        = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-lambda-logging-${var.function_settings.function_key}"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.iam_policy_document_cloudwatch_log_group.json
}
