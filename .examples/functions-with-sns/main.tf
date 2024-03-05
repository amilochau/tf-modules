terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  required_version = ">= 1.7.3, < 2.0.0"
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

resource "aws_sns_topic" "sns_topic" {
  # SNS topic, to be created by the process that publishes the event
  name           = "sns-topic-sample"
  tracing_config = "Active"

  provider = aws.workloads
}

module "functions_app" {
  source  = "../../aws/functions-app"
  context = var.context
  depends_on = [
    aws_sns_topic.sns_topic
  ]

  lambda_settings = {
    architecture = "arm64"
    runtime      = "nodejs18.x"
    functions = {
      "get" = {
        deployment_source_file_path = "data/handler.mjs"
        deployment_file_path        = "data/app.zip"
        handler                     = "handler.get"
        sns_triggers = [{
          topic_arn = aws_sns_topic.sns_topic.arn
        }]
      }
    }
  }

  providers = {
    aws.workloads = aws.workloads
  }
}
