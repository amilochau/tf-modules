terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
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
  source  = "../../shared/checks"
  context = var.context
}

module "functions_app" {
  source  = "../../aws/functions-app"
  context = var.context

  cognito_clients_settings = {
    "client" = {
      purpose = "Web UI"
    }
  }

  lambda_settings = {
    architecture = "arm64"
    runtime      = "nodejs18.x"
    functions = {
      "get" = {
        deployment_source_file_path = "data/handler.mjs"
        deployment_file_path        = "data/app.zip"
        handler                     = "handler.get"
        http_triggers = [{
          method = "GET"
          route  = "/hello"
          }, {
          method = "GET"
          route  = "/hola"
        }]
      }
    }
  }

  providers = {
    aws.workloads = aws.workloads
  }
}
