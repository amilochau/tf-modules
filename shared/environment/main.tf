locals {
  environment_name = startswith(var.conventions.host_name, "shd") ? "Shared" : startswith(var.conventions.host_name, "prd") ? "Production" : startswith(var.conventions.host_name, "stg") ? "Staging" : "Development"
  is_production    = local.environment_name == "Shared" || local.environment_name == "Production"
  is_temporary     = var.conventions.temporary
}
