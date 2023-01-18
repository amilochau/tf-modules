output "domain_verification_token" {
  description = "Verification token to add in domain DNS as TXT value"
  value = module.emails.domain_verification_token
}
