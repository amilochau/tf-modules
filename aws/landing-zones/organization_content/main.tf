terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26, < 6.0.0"
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

resource "aws_organizations_organizational_unit" "ou_organization" {
  name      = var.organization_full_name
  parent_id = var.root_id
}

# Deployments

module "deployments" {
  source = "./deployments"

  ou_organization_id     = aws_organizations_organizational_unit.ou_organization.id
  organization_full_name = var.organization_full_name
  deployments_settings   = var.deployments_settings
}

# Infrastructure

module "infrastructure" {
  source = "./infrastructure"

  ou_organization_id      = aws_organizations_organizational_unit.ou_organization.id
  organization_full_name  = var.organization_full_name
  infrastructure_settings = var.infrastructure_settings
}

# Workloads

module "workloads" {
  source = "./workloads"

  ou_organization_id     = aws_organizations_organizational_unit.ou_organization.id
  organization_full_name = var.organization_full_name
  workloads_settings     = var.workloads_settings
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
