terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
}

resource "aws_ssoadmin_permission_set" "permission_set" {
  instance_arn     = var.identity_center_arn
  name             = var.permission_set.name
  description      = var.permission_set.description
  session_duration = var.permission_set.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "permission_set_managed_policy_attachment" {
  for_each           = { for v in var.permission_set.managed_policy_arns : v => v }
  instance_arn       = var.identity_center_arn
  managed_policy_arn = each.value
  permission_set_arn = aws_ssoadmin_permission_set.permission_set.arn
}
