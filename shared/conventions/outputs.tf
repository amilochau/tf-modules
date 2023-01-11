output "aws_naming_conventions" {
  description = "Naming conventions for AWS"
  value       = local.aws_naming
}

output "aws_format_conventions" {
  description = "Format conventions for AWS"
  value       = local.aws_format
}

output "aws_existing_conventions" {
  description = "Existing resources conventions for AWS"
  value       = local.aws_existing
}
