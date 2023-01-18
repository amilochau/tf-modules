output "domain_verification_token" {
  description = "Verification token to add in domain DNS as TXT value"
  value = var.emails_domain != null ? aws_ses_domain_identity.domain_identity[0].verification_token : null
}
