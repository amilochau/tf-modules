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

resource "aws_resourceexplorer2_index" "resourceexplorer_index_local" {
  type = "LOCAL"
}

resource "aws_resourceexplorer2_index" "resourceexplorer_index_aggregate" {
  count = var.region_type == "Primary" ? 1 : 0
  type  = var.region_type == "AGGREGATE"
}
