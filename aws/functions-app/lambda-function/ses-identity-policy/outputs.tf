output "ses_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = data.aws_ses_domain_identity.ses_identity.arn
}
