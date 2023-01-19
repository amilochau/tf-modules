output "domain_verification_record" {
  description = "Verification records to add in domain DNS as TXT records"
  value = module.emails.domain_verification_record
}

output "domain_dkim_records" {
  description = "DKIM records to add in domain DNS as CNAME records"
  value = module.emails.domain_dkim_records
}

output "domain_mail_from_records" {
  description = "Records to add, so that MAIL FROM can be authenticated"
  value = module.emails.domain_mail_from_records
}

output "domain_dmarc_records" {
  description = "DMARC records to add in domain DNS as TXT records"
  value = module.emails.domain_dmarc_records
}
