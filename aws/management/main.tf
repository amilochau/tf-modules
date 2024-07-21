terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.59.0, < 6.0.0"
    }
  }

  required_version = ">= 1.9.2, < 2.0.0"
}

module "environment" {
  source  = "../../shared/environment"
  context = var.context
}

module "conventions" {
  source  = "../../shared/conventions"
  context = var.context
}

resource "aws_account_primary_contact" "account_primary_contact" {
  count = var.account_primary_contact == null ? 0 : 1

  full_name          = var.account_primary_contact.full_name
  company_name       = var.account_primary_contact.company_name
  address_line_1     = var.account_primary_contact.address_line_1
  city               = var.account_primary_contact.city
  postal_code        = var.account_primary_contact.postal_code
  district_or_county = var.account_primary_contact.district_or_county
  state_or_region    = var.account_primary_contact.state_or_region
  country_code       = var.account_primary_contact.country_code
  phone_number       = var.account_primary_contact.phone_number
  website_url        = var.account_primary_contact.website_url
}

/* @todo how to enforce that for multi-account?
resource "aws_s3_account_public_access_block" "s3_account_public_access_block" {
  count = var.region_type == "Primary" ? 1 : 0

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
*/

resource "aws_resourceexplorer2_index" "resourceexplorer_index" {
  type = var.region_type == "Primary" ? "AGGREGATOR" : "LOCAL"
}

resource "aws_resourceexplorer2_view" "default_view" {
  name         = "Default"
  default_view = true
}

module "budgets" {
  for_each = var.budgets
  source   = "./budget"

  context = var.context
  budget_settings = {
    name             = each.key
    limit_amount_usd = each.value.limit_amount_usd
    notifications    = each.value.notifications
  }
}
