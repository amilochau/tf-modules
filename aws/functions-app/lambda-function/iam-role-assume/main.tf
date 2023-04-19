module "conventions" {
  source      = "../../../../shared/conventions"
  conventions = var.conventions
}

data "aws_iam_policy_document" "lambda_iam_policy_document" {
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
    # @todo Add condition: only from current account + only from the current lambda function
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  name               = "${module.conventions.aws_naming_conventions.iam_role_name_prefix}-lambda-${var.function_settings.function_key}"
  description        = "IAM role used by the lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_policy_document.json
}
