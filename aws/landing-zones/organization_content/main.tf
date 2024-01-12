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
  name      = var.organization_name
  parent_id = var.root_id
}

# Deployments

resource "aws_organizations_organizational_unit" "ou_deployments" {
  name      = "${var.organization_name}-deployments"
  parent_id = aws_organizations_organizational_unit.ou_organization.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "ou_deployments_prod" {
  name      = "${var.organization_name}-deployments-prod"
  parent_id = aws_organizations_organizational_unit.ou_deployments.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_account" "account_deployments_prod_shared" {
  name      = "${var.organization_name}-deployments-prod-shared"
  email     = var.deployments_settings.account_email_prod_shared
  parent_id = aws_organizations_organizational_unit.ou_deployments_prod.id
}

# Infrastructure

resource "aws_organizations_organizational_unit" "ou_infrastructure" {
  name      = "${var.organization_name}-infrastructure"
  parent_id = aws_organizations_organizational_unit.ou_organization.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "ou_infrastructure_prod" {
  name      = "${var.organization_name}-infrastructure-prod"
  parent_id = aws_organizations_organizational_unit.ou_infrastructure.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_account" "account_infrastructure_prod_shared" {
  name      = "${var.organization_name}-infrastructure-prod-shared"
  email     = var.infrastructure_settings.account_email_prod_shared
  parent_id = aws_organizations_organizational_unit.ou_infrastructure_prod.id
}

# Workloads

resource "aws_organizations_organizational_unit" "ou_workloads" {
  name      = "${var.organization_name}-workloads"
  parent_id = aws_organizations_organizational_unit.ou_organization.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "ou_workloads_prod" {
  name      = "${var.organization_name}-workloads-prod"
  parent_id = aws_organizations_organizational_unit.ou_workloads.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "ou_workloads_test" {
  name      = "${var.organization_name}-workloads-test"
  parent_id = aws_organizations_organizational_unit.ou_workloads.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_account" "account_workloads_prod" {
  for_each = var.workloads_settings

  name      = "${var.organization_name}-workloads-prod-${each.key}"
  email     = each.value.account_email_prod
  parent_id = aws_organizations_organizational_unit.ou_workloads_prod.id
}

resource "aws_organizations_account" "account_workloads_test" {
  for_each = var.workloads_settings

  name      = "${var.organization_name}-workloads-test-${each.key}"
  email     = each.value.account_email_test
  parent_id = aws_organizations_organizational_unit.ou_workloads_test.id
}

# Additional - not enabled yet

/*

resource "aws_organizations_organizational_unit" "ou_security" {
  name      = "${var.organization_name}-security"
  parent_id = var.parent_organizational_unit_id
}

resource "aws_organizations_organizational_unit" "ou_policystaging" {
  name      = "${var.organization_name}-policy-staging"
  parent_id = var.parent_organizational_unit_id
}

resource "aws_organizations_organizational_unit" "ou_individualbusinessusers" {
  name      = "${var.organization_name}-individual-business-users"
  parent_id = var.parent_organizational_unit_id
}

resource "aws_organizations_organizational_unit" "ou_exceptions" {
  name      = "${var.organization_name}-exceptions"
  parent_id = var.parent_organizational_unit_id
}

*/
