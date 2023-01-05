variable conventions {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name = string
    host_name = string
  })
}

locals {
  cognito_userpool_name = "${var.conventions.organization_name}-${var.conventions.application_name}-${var.conventions.host_name}-cognito-userpool"
}
