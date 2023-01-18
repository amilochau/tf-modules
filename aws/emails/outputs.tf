output "domain_verification_token" {
  description = "Verification token to add in domain DNS as TXT value"
  value = aws_ses_domain_identity.domain_identity.verification_token
}
