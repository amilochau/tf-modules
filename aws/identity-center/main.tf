terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.37, < 6.0.0"
    }
  }

  required_version = ">= 1.7.3, < 2.0.0"
}

module "environment" {
  source  = "../../shared/environment"
  context = var.context
}

module "conventions" {
  source  = "../../shared/conventions"
  context = var.context
}

data "aws_ssoadmin_instances" "identity_center_instances" {}

module "permission_set" {
  for_each = var.permission_sets
  source   = "./permission-set"

  identity_center_arn = tolist(data.aws_ssoadmin_instances.identity_center_instances.arns)[0]
  permission_set = {
    name                = each.key
    description         = each.value.description
    session_duration    = each.value.session_duration
    managed_policy_arns = each.value.managed_policy_arns
  }
}

resource "aws_identitystore_group" "group" {
  for_each = var.groups

  identity_store_id = tolist(data.aws_ssoadmin_instances.identity_center_instances.identity_store_ids)[0]
  display_name      = each.value.display_name
  description       = each.value.description
}

# IAM OIDC between AWS and GitHub

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_identity_provider" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com"
  ]
  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint // Thumbprint for GitHub Actions
  ]
}
