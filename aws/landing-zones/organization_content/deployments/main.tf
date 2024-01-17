resource "aws_organizations_organizational_unit" "ou_deployments" {
  name      = "${var.organization_full_name}-deployments"
  parent_id = var.ou_organization_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "ou_deployments_prod" {
  name      = "${var.organization_full_name}-deployments-prod"
  parent_id = aws_organizations_organizational_unit.ou_deployments.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_account" "account_deployments_prod_shared" {
  name      = "${var.organization_full_name}-deployments-prod-shared"
  email     = var.deployments_settings.account_email_prod_shared
  parent_id = aws_organizations_organizational_unit.ou_deployments_prod.id
}
