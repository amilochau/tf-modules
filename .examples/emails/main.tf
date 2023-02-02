terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.50, < 5.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  profile = var.aws_provider_settings.profile
  region  = var.aws_provider_settings.region

  default_tags {
    tags = {
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

module "emails" {
  source      = "../../aws/emails"
  conventions = var.conventions

  domains = {
    "example.com" = {
      mail_from_subdomain = "mail"
    }
  }

  templates = {
    "template1" = {
      subject = "Welcome {{name}}!"
      html = file("${path.module}/email-templates/template1/template.html")
      text = file("${path.module}/email-templates/template1/template.txt")
    }
  }
}
