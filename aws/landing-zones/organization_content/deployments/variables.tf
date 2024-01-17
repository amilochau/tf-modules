variable "organization_full_name" {
  description = "Organization long name"
  type        = string
}

variable "ou_organization_id" {
  description = "OU organization ID"
  type        = string
}

variable "deployments_settings" {
  description = "Deployments settings"
  type = object({
    account_email_prod_shared = string
  })
}
