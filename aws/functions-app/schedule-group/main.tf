terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0, < 6.0.0"
      configuration_aliases = [
        aws.workloads
      ]
    }
  }

  required_version = ">= 1.8.0, < 2.0.0"
}

module "conventions" {
  source  = "../../../shared/conventions"
  context = var.context
}

resource "aws_scheduler_schedule_group" "schedule_group" {
  name = module.conventions.aws_naming_conventions.eventbridge_schedule_group_name

  provider = aws.workloads
}
