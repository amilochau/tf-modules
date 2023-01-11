terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.44"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  profile = var.aws_provider_settings.profile
  region  = var.aws_provider_settings.region

  default_tags {
    tags = {
      organization = var.conventions.organization_name
      application  = var.conventions.application_name
      host         = var.conventions.host_name
      creator      = "AMI"
    }
  }
}

module "checks" {
  source      = "../../shared/checks"
  conventions = var.conventions
}

module "functions_app" {
  source      = "../../aws/functions-app"
  conventions = var.conventions

  lambda_settings = {
    memory_size_mb       = 128
    architecture         = "arm64"
    runtime              = "nodejs18.x"
    deployment_file_path = "data/app.zip"
    handler              = "handler.get"
    expose_apis          = false
  }
}
