terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  required_version = ">= 1.6.3, < 2.0.0"
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

module "checks" {
  source      = "../../shared/checks"
  context = var.context
}

module "emails" {
  source      = "../../aws/emails"
  context = var.context

  domains = {
    "example.com" = {
      zone_name           = "test.com"
      mail_from_subdomain = "mail"
    }
  }

  templates = {
    "template1" = {
      subject = "Welcome {{name}}!"
      html    = file("${path.module}/email-templates/template1/template.html")
      text    = file("${path.module}/email-templates/template1/template.txt")
    }
  }

  providers = {
    aws.infrastructure = aws.workloads
    aws.workloads      = aws.workloads
  }
}
