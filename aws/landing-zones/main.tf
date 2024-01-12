terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26, < 6.0.0"
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

resource "aws_organizations_organization" "organization" {
  aws_service_access_principals = [
    "account.amazonaws.com",
    "sso.amazonaws.com"
  ]
}

# Management & Sandbox

resource "aws_organizations_account" "account_management" {
  name  = "management"
  email = var.management_settings.account_email
}

resource "aws_organizations_account" "account_sandbox" {
  name  = "sandbox"
  email = var.sandbox_settings.account_email
}

resource "aws_organizations_organizational_unit" "ou_suspended" {
  name      = "suspended"
  parent_id = aws_organizations_organization.organization.roots[0].id
}

# Organization content

module "organization_content" {
  for_each = var.organizations_settings
  source   = "./organization_content"

  root_id                 = aws_organizations_organization.organization.roots[0].id
  organization_name       = each.key
  deployments_settings    = each.value.deployments
  infrastructure_settings = each.value.infrastructure
  workloads_settings      = each.value.workloads
}
