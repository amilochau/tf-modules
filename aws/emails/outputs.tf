output "domain_verification_record" {
  description = "TXT record to add, so that domain can be verified"
  value = var.domain != null ? {
    type = "TXT"
    name = "_amazonses.${aws_ses_domain_identity.domain_identity[0].domain}"
    record = aws_ses_domain_identity.domain_identity[0].verification_token
  } : null
}

output "domain_dkim_records" {
  description = "CNAME record to add, so that domain can be authenticated with DKIM"
  value = var.domain != null ? [
    for v in aws_ses_domain_dkim.domain_dkim[0].dkim_tokens : {
      type = "CNAME"
      name = "${v}._domainkey.${aws_ses_domain_identity.domain_identity[0].domain}"
      record = "${v}.dkim.amazonses.com"
    }
  ] : null
}

output "domain_mail_from_records" {
  description = "Records to add, so that MAIL FROM can be authenticated"
  value = var.domain != null && var.mail_from_subdomain != null ? [
    {
      type = "MX"
      name = aws_ses_domain_mail_from.domain_mail_from[0].mail_from_domain
      record = "10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"
    },
    {
      type = "TXT"
      name = aws_ses_domain_mail_from.domain_mail_from[0].mail_from_domain
      record = "v=spf1 include:amazonses.com ~all"
    }
  ] : null
}

output "domain_dmarc_records" {
  description = "TXT to add, so that domain can be authenticated with DMARC"
  value = var.domain != null ? {
    type = "TXT"
    name = "_dmarc.${aws_ses_domain_identity.domain_identity[0].domain}"
    record = "v=DMARC1;p=none" # see https://www.rfc-editor.org/rfc/rfc7489#section-6.3
  } : null
}
