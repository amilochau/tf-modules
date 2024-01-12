terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

provider "aws" {
  region = var.aws_provider_settings.region
}

module "landing_zones" {
  source = "../../aws/landing-zones"

  account_settings = {
    email = "test@example.fr"
  }
}
