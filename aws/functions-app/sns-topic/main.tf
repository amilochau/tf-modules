terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.9.8, < 2.0.0"
}

module "environment" {
  source  = "../../../shared/environment"
  context = var.context
}

module "conventions" {
  source  = "../../../shared/conventions"
  context = var.context
}

resource "aws_sns_topic" "sns_topic" {
  name           = "${module.conventions.aws_naming_conventions.sns_topic_name_prefix}-${var.topic_settings.name}"
  tracing_config = "Active"

  provider = aws.workloads
}
