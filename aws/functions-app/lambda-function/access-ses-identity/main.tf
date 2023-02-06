module "conventions" {
  source      = "../../../../shared/conventions"
  conventions = var.conventions
}

data "aws_caller_identity" "caller_identity" {}

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
    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.caller_identity.account_id
      ]
    }
    effect = "Allow"
  }
}

resource "aws_ses_identity_policy" "lambda_ses_identity_policy" {
  identity    = data.aws_ses_domain_identity.ses_identity.arn
  name        = "${module.conventions.aws_naming_conventions.ses_identity_policy_name_prefix}-lambda-ses-${replace(var.ses_domain, ".", "_")}"
  policy      = data.aws_iam_policy_document.lambda_iam_policy_document_dynamodb.json
}
