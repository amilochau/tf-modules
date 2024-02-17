terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.37, < 6.0.0"
    }
  }

  required_version = ">= 1.7.3, < 2.0.0"
}

module "conventions" {
  source  = "../../shared/conventions"
  context = var.context
}

data "aws_iam_policy_document" "iam_policy_document_github_assume" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type        = "Federated"
      identifiers = [var.github_identity_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.organization_name}/*:*"
      ]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "iam_role" {
  name               = "${module.conventions.aws_naming_conventions.iam_role_name_prefix}-github-${var.organization_name}"
  description        = "IAM role used by GitHub Actions to execute"
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document_github_assume.json
}

// IAM Policy & role to allow GitHub deploying resources

data "aws_iam_policy_document" "iam_policy_document_github" {
  statement {
    actions = [
      "*"
    ]
    resources = [
      "*"
    ]
    dynamic "condition" {
      for_each = length(var.aws_accounts) > 0 ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:ResourceAccount"
        values   = var.aws_accounts
      }
    }
    # @todo add condition here - see https://dev.to/mmiranda/github-actions-authenticating-on-aws-using-oidc-3d2n
    # See also https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html#access_iam-tags
    effect = "Allow"
  }
}

resource "aws_iam_policy" "iam_policy" {
  name        = "${module.conventions.aws_naming_conventions.iam_policy_name_prefix}-github-${var.organization_name}"
  description = "IAM policy used by GitHub Actions to deploy AWS resources"
  policy      = data.aws_iam_policy_document.iam_policy_document_github.json
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.iam_policy.arn
}
