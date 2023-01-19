output "domain_verification_name" {
  description = "Name of the TXT record to add, so that domain can be verified"
  value = "_amazonses.${aws_ses_domain_identity.domain_identity[0].domain}"
}

output "domain_verification_token" {
  description = "Token of TXT record to add, so that domain can be verified"
  value = var.emails_domain != null ? aws_ses_domain_identity.domain_identity[0].verification_token : null
}
