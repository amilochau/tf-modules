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

module "functions_app" {
  source      = "../../aws/functions-app"
  conventions = var.conventions

  lambda_settings = {
    architecture         = "arm64"
    runtime              = "nodejs18.x"
    functions = {
      "get" = {
        deployment_file_path = "data/app.zip"
        handler = "handler.get"
        environment_variables = {
          "CONVENTION__HOST" = "THIS VALUE SHOULD NOT BE USED - AS IT MUST BE OVERRIDED BY TEMPLATE",
          "key1" = "value1"
        }
      }
    }
  }
}
