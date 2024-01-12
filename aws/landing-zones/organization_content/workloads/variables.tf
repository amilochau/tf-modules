variable "organization_name" {
  description = "Organization name"
  type        = string
}

variable "ou_organization_id" {
  description = "OU organization ID"
  type = string
}

variable "workloads_settings" {
  description = "Workloads settings"
  type = map(object({
    account_email_prod = string
    account_email_test = string
  }))
}
