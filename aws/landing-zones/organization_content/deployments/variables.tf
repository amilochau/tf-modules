variable "organization_name" {
  description = "Organization name"
  type        = string
}

variable "ou_organization_id" {
  description = "OU organization ID"
  type = string
}

variable "deployments_settings" {
  description = "Deployments settings"
  type = object({
    account_email_prod_shared = string
  })
}
