output "environment_name" {
  description = "Environment name"
  value       = local.environment_name
}

output "is_production" {
  description = "Is the current environment used by Production resources"
  value       = local.is_production
}
