data "aws_ssoadmin_instances" "iam_identity_center" {}

resource "aws_organizations_account" "account" {
  name      = var.account_name
  email     = var.account_email
  parent_id = var.account_parent_id
  role_name = "administrator-access"

  lifecycle {
    ignore_changes = [
      role_name
    ]
  }
}

resource "aws_ssoadmin_account_assignment" "account_assignment" {
  for_each = var.account_iam_assignments

  instance_arn       = tolist(data.aws_ssoadmin_instances.iam_identity_center.arns)[0]
  permission_set_arn = each.value.permission_set_arn

  principal_id   = each.value.principal_id
  principal_type = each.value.principal_type

  target_id   = aws_organizations_account.account.id
  target_type = "AWS_ACCOUNT"
}
