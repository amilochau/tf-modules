output "domain_verification_record" {
  description = "DNS records to add, so that domains can be verified"
  value = module.emails.domain_records
}
