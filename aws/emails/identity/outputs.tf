output "domain_records" {
  description = "TXT record to add, so that domain can be verified"
  value = concat(
    [
      {
        comment = "SPF verification"
        type = "MX"
        name = "${var.mail_from_subdomain}.${aws_sesv2_email_identity.identity.email_identity}"
        record = "10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"
      },
      {
        comment = "SPF verification"
        type = "TXT"
        name = "${var.mail_from_subdomain}.${aws_sesv2_email_identity.identity.email_identity}"
        record = "v=spf1 include:amazonses.com ~all"
      },
      {
        comment = "DMARC verification"
        type = "TXT"
        name = "_dmarc.${aws_sesv2_email_identity.identity.email_identity}"
        record = "v=DMARC1;p=none" # see https://www.rfc-editor.org/rfc/rfc7489#section-6.3
      }
    ],
    flatten([
      for v in aws_sesv2_email_identity.identity.dkim_signing_attributes : [
        for v2 in v.tokens : {
          comment = "DKIM tokens"
          type = "CNAME"
          name = "${v2}._domainkey.${aws_sesv2_email_identity.identity.email_identity}"
          record = "${v2}.dkim.amazonses.com"
        }
      ]
    ])
  )
}