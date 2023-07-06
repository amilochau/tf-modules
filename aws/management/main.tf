terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.62, < 5.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

module "environment" {
  source      = "../../shared/environment"
  conventions = var.conventions
}

module "conventions" {
  source      = "../../shared/conventions"
  conventions = var.conventions
}

resource "aws_account_primary_contact" "account_primary_contact" {
  count = var.account_primary_contact == null ? 0 : 1

  address_line_1     = var.account_primary_contact.address_line_1
  city               = var.account_primary_contact.city
  company_name       = var.account_primary_contact.company_name
  country_code       = var.account_primary_contact.country_code
  district_or_county = var.account_primary_contact.district_or_county
  full_name          = var.account_primary_contact.full_name
  phone_number       = var.account_primary_contact.phone_number
  postal_code        = var.account_primary_contact.postal_code
  state_or_region    = var.account_primary_contact.state_or_region
  website_url        = var.account_primary_contact.website_url
}

resource "aws_resourceexplorer2_index" "resourceexplorer_index" {
  type = var.region_type == "Primary" ? "AGGREGATOR" : "LOCAL"
}

resource "aws_resourceexplorer2_view" "default_view" {
  name         = "Default"
  default_view = true
}

module "domains" {
  for_each = var.domains
  source   = "./domain"

  conventions = var.conventions
  domain_settings = {
    domain_name        = each.key
    domain_description = each.value.domain_description
    records            = each.value.records
  }
}

module "budgets" {
  for_each = var.budgets
  source   = "./budget"

  conventions = var.conventions
  budget_settings = {
    name             = each.key
    limit_amount_usd = each.value.limit_amount_usd
    notifications    = each.value.notifications
  }
}
