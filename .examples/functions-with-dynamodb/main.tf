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

module "functions_app" {
  source      = "../../aws/functions-app"
  conventions = var.conventions

  dynamodb_tables_settings = {
    "table1" = {
      partition_key = "hash"
      sort_key      = "range"
    }
  }

  lambda_settings = {
    architecture = "arm64"
    runtime      = "nodejs18.x"

    functions = {
      "get" = {
        deployment_source_file_path = "data/get.js"
        deployment_file_path = "data/app.zip"
        handler              = "handler.get"
        http_triggers = [{
          method = "GET"
          route  = "/{proxy+}"
        }]
      }
    }
  }
}
