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
