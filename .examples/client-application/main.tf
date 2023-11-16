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

  default_tags {
    tags = {
      application = var.conventions.application_name
      host        = var.conventions.host_name
    }
  }
}

provider "aws" {
  alias  = "no-tags"
  region = var.aws_provider_settings.region
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

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
  source      = "../../aws/static-web-app"
  conventions = var.conventions

  client_settings = {
    package_source_file   = "./dist"
    s3_bucket_name_suffix = "1"
  }

  providers = {
    aws.no-tags   = aws.no-tags
    aws.us-east-1 = aws.us-east-1
  }
}
