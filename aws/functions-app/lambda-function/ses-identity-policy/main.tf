terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
}

module "conventions" {
  source  = "../../../../shared/conventions"
  context = var.context
}

data "aws_caller_identity" "caller_identity" {
  provider = aws.workloads
}

data "aws_ses_domain_identity" "ses_identity" {
  domain = var.ses_domain

  provider = aws.workloads
}

data "aws_iam_policy_document" "lambda_iam_policy_document_ses" {
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
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn" # Case is important here!

      values = [
        var.function_arn
      ]
    }
    effect = "Allow"
  }
}

resource "aws_ses_identity_policy" "lambda_ses_identity_policy" {
  name     = "${module.conventions.aws_naming_conventions.ses_identity_policy_name_prefix}-fn-ses-${replace(var.ses_domain, ".", "_")}"
  identity = data.aws_ses_domain_identity.ses_identity.arn
  policy   = data.aws_iam_policy_document.lambda_iam_policy_document_ses.json

  provider = aws.workloads
}
