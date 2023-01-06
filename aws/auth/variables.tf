variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
}

locals {
  environment_name = startswith(var.host_name, "shd") ? "Shared" : startswith(var.host_name, "prd") ? "Production" : startswith(var.host_name, "stg") ? "Staging" : "Development"
  is_production    = environment_name == "Shared" || environment_name == "Production"
}

locals {
  cognito_userpool_name = "${var.conventions.organization_name}-${var.conventions.application_name}-${var.conventions.host_name}-cognito-userpool"
}
