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
      organization = var.conventions.organization_name
      application  = var.conventions.application_name
      host         = var.conventions.host_name
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
    "source" = {
      partition_key = "id"
      enable_stream = true
    }
    "destination" = {
      partition_key = "id"
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
        dynamodb_stream_triggers = [{
          description = "React to changes in source table"
          table_name  = "source"
          filter_criteria_patterns = [
            "{ \"dynamodb\": { \"NewImage\": { \"mapName\": { \"S\": [\"map 1\"] } } } }"
          ]
        }]
      }
    }
  }
}
