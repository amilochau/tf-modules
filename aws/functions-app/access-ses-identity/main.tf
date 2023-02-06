module "conventions" {
  source      = "../../../shared/conventions"
  conventions = var.conventions
}

data "aws_ses_domain_identity" "ses_identity" {
  domain = var.ses_domain
}

data "aws_iam_policy_document" "lambda_iam_policy_document_dynamodb" {
  statement {
    actions = [
      "ses:SendTemplatedEmail"
    ]
    resources = [
      data.aws_ses_domain_identity.ses_identity.arn
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "lambda_iam_policy_ses" {
  name        = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-lambda-ses-${var.ses_domain}"
  description = "IAM policy for using a SES domain from a lambda"
  policy      = data.aws_iam_policy_document.lambda_iam_policy_document_dynamodb.json
}
