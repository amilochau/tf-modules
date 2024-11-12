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

module "conventions" {
  source  = "../../../shared/conventions"
  context = var.context
}

# ===== CLOUDWATCH LOG GROUP =====

resource "aws_cloudwatch_log_group" "cloudwatch_loggroup_lambda" {
  name              = module.conventions.aws_naming_conventions.cloudwatch_log_group_name
  retention_in_days = module.conventions.aws_format_conventions.cloudwatch_log_group_retention_days

  provider = aws.workloads
}
