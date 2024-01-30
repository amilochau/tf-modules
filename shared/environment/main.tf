locals {
  environment_name = startswith(var.context.host_name, "shd") ? "Shared" : startswith(var.context.host_name, "prd") ? "Production" : startswith(var.context.host_name, "stg") ? "Staging" : "Development"
  is_production    = local.environment_name == "Shared" || local.environment_name == "Production"
  is_temporary     = var.context.temporary
}
