terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region  = var.aws_provider_settings.region

  default_tags {
    tags = {
      application = var.conventions.application_name
      host        = var.conventions.host_name
    }
  }
}

module "checks" {
  source      = "../../shared/checks"
  conventions = var.conventions
}

module "client_app" {
  source = "../../aws/static-web-app"
  conventions = var.conventions

  client_settings = {
    package_source_file = "./dist"
    s3_bucket_name_suffix = "1"
  }
}
