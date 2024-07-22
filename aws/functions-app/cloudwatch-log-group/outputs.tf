output "cloudwatch_log_group_arn" {
  description = "Cloudwatch log group ARN"
  value       = aws_cloudwatch_log_group.cloudwatch_loggroup_lambda.arn
}

output "cloudwatch_log_group_name" {
  description = "Cloudwatch log group name"
  value       = aws_cloudwatch_log_group.cloudwatch_loggroup_lambda.name
}
