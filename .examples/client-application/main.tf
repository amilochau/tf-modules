terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.59.0, < 6.0.0"
    }
  }

  required_version = ">= 1.9.2, < 2.0.0"
}

provider "aws" {
  alias  = "workloads"
  region = var.aws_provider_settings.region

  assume_role {
    role_arn = var.assume_roles.sandbox
  }

  default_tags {
    tags = {
      organization = var.context.organization_name
      application  = var.context.application_name
      host         = var.context.host_name
    }
  }
}

provider "aws" {
  alias  = "workloads-us-east-1"
  region = "us-east-1"

  assume_role {
    role_arn = var.assume_roles.sandbox
  }

  default_tags {
    tags = {
      organization = var.context.organization_name
      application  = var.context.application_name
      host         = var.context.host_name
    }
  }
}

provider "aws" {
  alias  = "infrastructure"
  region = "us-east-1"

  assume_role {
    role_arn = var.assume_roles.sandbox
  }

  default_tags {
    tags = {
      organization = var.context.organization_name
      application  = var.context.application_name
      host         = var.context.host_name
    }
  }
}

module "checks" {
  source  = "../../shared/checks"
  context = var.context
}

module "client_app" {
  source  = "../../aws/static-web-app"
  context = var.context

  client_settings = {
    package_source_file   = "./dist"
    s3_bucket_name_suffix = "1"
  }

  providers = {
    aws.infrastructure    = aws.infrastructure
    aws.workloads         = aws.workloads
    aws.workloads-us-east = aws.workloads-us-east-1
  }
}
