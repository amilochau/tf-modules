resource "aws_organizations_organizational_unit" "ou_infrastructure" {
  name      = "${var.organization_full_name}-infrastructure"
  parent_id = var.ou_organization_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "ou_infrastructure_prod" {
  name      = "${var.organization_full_name}-infrastructure-prod"
  parent_id = aws_organizations_organizational_unit.ou_infrastructure.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_organizations_account" "account_infrastructure_prod_shared" {
  name      = "${var.organization_full_name}-infrastructure-prod-shared"
  email     = var.infrastructure_settings.account_email_prod_shared
  parent_id = aws_organizations_organizational_unit.ou_infrastructure_prod.id
}
