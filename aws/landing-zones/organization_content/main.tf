terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
}

resource "aws_organizations_organizational_unit" "ou_organization" {
  name      = var.organization_full_name
  parent_id = var.root_id
}

# Deployments

module "deployments" {
  source = "../account"

  account_name            = "${var.organization_full_name}-deployments"
  account_email           = var.deployments_settings.account_email
  account_parent_id       = aws_organizations_organizational_unit.ou_organization.id
  account_iam_assignments = var.default_account_iam_assignments
}

# Infrastructure

module "infrastructure" {
  source = "../account"

  account_name            = "${var.organization_full_name}-infrastructure"
  account_email           = var.infrastructure_settings.account_email
  account_parent_id       = aws_organizations_organizational_unit.ou_organization.id
  account_iam_assignments = var.default_account_iam_assignments
}

# Workloads

module "workloads_prod" {
  source = "../account"

  account_name            = "${var.organization_full_name}-workloads-prod"
  account_email           = var.workloads_settings.account_email_prod
  account_parent_id       = aws_organizations_organizational_unit.ou_organization.id
  account_iam_assignments = var.default_account_iam_assignments
}
module "workloads_test" {
  source = "../account"

  account_name            = "${var.organization_full_name}-workloads-test"
  account_email           = var.workloads_settings.account_email_test
  account_parent_id       = aws_organizations_organizational_unit.ou_organization.id
  account_iam_assignments = var.default_account_iam_assignments
}

# Additional - not enabled yet

/*

resource "aws_organizations_organizational_unit" "ou_security" {
  name      = "${var.organization_full_name}-security"
  parent_id = var.parent_organizational_unit_id
}

resource "aws_organizations_organizational_unit" "ou_policystaging" {
  name      = "${var.organization_full_name}-policy-staging"
  parent_id = var.parent_organizational_unit_id
}

resource "aws_organizations_organizational_unit" "ou_individualbusinessusers" {
  name      = "${var.organization_full_name}-individual-business-users"
  parent_id = var.parent_organizational_unit_id
}

resource "aws_organizations_organizational_unit" "ou_exceptions" {
  name      = "${var.organization_full_name}-exceptions"
  parent_id = var.parent_organizational_unit_id
}

*/
