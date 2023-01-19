output "domain_verification_record" {
  description = "TXT record to add, so that domain can be verified"
  value = var.emails_domain != null ? {
    name = "_amazonses.${aws_ses_domain_identity.domain_identity[0].domain}"
    record = aws_ses_domain_identity.domain_identity[0].verification_token
  } : null
}

output "domain_dkim_records" {
  description = "CNAME record to add, so that domain can be authenticated"
  value = var.emails_domain != null ? [
    for v in aws_ses_domain_dkim.domain_dkim[0].dkim_tokens : {
      name = "${v}._domainkey"
      record = "${v}.dkim.amazonses.com"
    }
  ] : null
}
