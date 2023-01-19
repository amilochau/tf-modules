output "domain_records" {
  description = "DNS records to add, so that domains can be verified"
  value = [
    for v in module.domains : v.domain_records
  ]
}
