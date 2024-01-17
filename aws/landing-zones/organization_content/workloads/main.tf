resource "aws_organizations_organizational_unit" "ou_workloads" {
  name      = "${var.organization_full_name}-workloads"
  parent_id = var.ou_organization_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "ou_workloads_prod" {
  name      = "${var.organization_full_name}-workloads-prod"
  parent_id = aws_organizations_organizational_unit.ou_workloads.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "ou_workloads_test" {
  name      = "${var.organization_full_name}-workloads-test"
  parent_id = aws_organizations_organizational_unit.ou_workloads.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_account" "account_workloads_prod" {
  for_each = var.workloads_settings

  name      = "${var.organization_full_name}-workloads-prod-${each.key}"
  email     = each.value.account_email_prod
  parent_id = aws_organizations_organizational_unit.ou_workloads_prod.id
}

resource "aws_organizations_account" "account_workloads_test" {
  for_each = var.workloads_settings

  name      = "${var.organization_full_name}-workloads-test-${each.key}"
  email     = each.value.account_email_test
  parent_id = aws_organizations_organizational_unit.ou_workloads_test.id
}
