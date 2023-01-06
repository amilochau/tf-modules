module "environment" {
  source = "../../shared/environment"
  conventions = var.conventions  
}

locals {
  aws_default_base = {
    prefix = "${var.conventions.organization_name}-${var.conventions.application_name}-${var.conventions.host_name}"
  }
}

locals {
  aws_default = {
    cognito_userpool_name = "${local.aws_default_base.prefix}-cognito-userpool"
  }
}

locals {
  aws_current = local.aws_default
}
