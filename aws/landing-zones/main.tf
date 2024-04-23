terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 6.0.0"
    }
  }

  required_version = ">= 1.7.3, < 2.0.0"
}

resource "aws_organizations_organization" "organization" {
  aws_service_access_principals = [
    "account.amazonaws.com",
    "resource-explorer-2.amazonaws.com",
    "sso.amazonaws.com",
  ]
}

# Management & Sandbox

module "account_management" {
  source = "./account"

  account_name            = "management"
  account_email           = var.management_settings.account_email
  account_iam_assignments = var.default_account_iam_assignments
}

module "account_sandbox" {
  source = "./account"

  account_name            = "sandbox"
  account_email           = var.sandbox_settings.account_email
  account_iam_assignments = var.default_account_iam_assignments
}

resource "aws_organizations_organizational_unit" "ou_suspended" {
  name      = "suspended"
  parent_id = aws_organizations_organization.organization.roots[0].id
}

# Organization content

module "organization_content" {
  for_each = var.organizations_settings
  source   = "./organization_content"

  root_id                         = aws_organizations_organization.organization.roots[0].id
  organization_full_name          = each.key
  deployments_settings            = each.value.deployments
  infrastructure_settings         = each.value.infrastructure
  workloads_settings              = each.value.workloads
  default_account_iam_assignments = var.default_account_iam_assignments
}
