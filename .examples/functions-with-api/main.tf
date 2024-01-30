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
          description = "Sample HTTP API for Lambda trigger"
          method      = "GET"
          route       = "/{proxy+}"
        }]
      }
    }
  }

  providers = {
    aws.workloads = aws.workloads
  }
}
