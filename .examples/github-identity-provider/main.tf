terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    github = {
      source = "integrations/github"
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
}

provider "aws" {
  region = var.aws_provider_settings.region

  default_tags {
    tags = {
      organization = var.conventions.organization_name
      application  = var.conventions.application_name
      host         = var.conventions.host_name
    }
  }
}

provider "github" {
  owner = var.github_provider_settings.owner
}

module "checks" {
  source      = "../../shared/checks"
  conventions = var.conventions
}

module "identity_provider" {
  source      = "../../github/identity-provider"
  conventions = var.conventions

  account_name = "amilochau"
}
