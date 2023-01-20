output "domain_identity_arn" {
  description = "ARN of the deployed SES domain identity"
  value = aws_ses_domain_identity.domain_identity.arn
}

output "domain_records" {
  description = "TXT record to add, so that domain can be verified"
  value = concat([{
    comment = "Domain identity verification"
    type = "TXT"
    name = "_amazonses.${aws_ses_domain_identity.domain_identity.domain}"
    record = aws_ses_domain_identity.domain_identity.verification_token
  },
  {
      comment = "SPF verification"
      type = "MX"
      name = aws_ses_domain_mail_from.domain_mail_from.mail_from_domain
      record = "10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"
    },
    {
      comment = "SPF verification"
      type = "TXT"
      name = aws_ses_domain_mail_from.domain_mail_from.mail_from_domain
      record = "v=spf1 include:amazonses.com ~all"
    },
    {
      comment = "DMARC verification"
    type = "TXT"
    name = "_dmarc.${aws_ses_domain_identity.domain_identity.domain}"
    record = "v=DMARC1;p=none" # see https://www.rfc-editor.org/rfc/rfc7489#section-6.3
  }
  ],
  [
    for v in aws_ses_domain_dkim.domain_dkim.dkim_tokens : {
      comment = "DKIM tokens"
      type = "CNAME"
      name = "${v}._domainkey.${aws_ses_domain_identity.domain_identity.domain}"
      record = "${v}.dkim.amazonses.com"
    }
  ]
  )
}
