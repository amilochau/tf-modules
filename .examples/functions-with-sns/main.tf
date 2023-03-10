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

resource "aws_sns_topic" "sns_topic" {
  # SNS topic, to be created by the process that publishes the event
  name = "sns-topic-sample"
}

module "functions_app" {
  source      = "../../aws/functions-app"
  conventions = var.conventions
  depends_on = [
    aws_sns_topic.sns_topic
  ]

  lambda_settings = {
    architecture = "arm64"
    runtime      = "nodejs18.x"
    functions = {
      "get" = {
        deployment_source_file_path = "data/get.js"
        deployment_file_path = "data/app.zip"
        handler              = "handler.get"
        sns_triggers = [{
          topic_name = aws_sns_topic.sns_topic.name
        }]
      }
    }
  }
}
