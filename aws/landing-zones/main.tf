terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.26, < 6.0.0"
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

resource "aws_organizations_account" "account_management" {
  name = "management"
  email = var.account_settings.email
}
