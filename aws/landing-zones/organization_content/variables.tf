variable "root_id" {
  description = "Root id"
  type        = string
}

variable "organization_full_name" {
  description = "Organization long name"
  type        = string
}

variable "deployments_settings" {
  description = "Deployments settings"
  type = object({
    account_email_prod_shared = string
  })
}

variable "infrastructure_settings" {
  description = "Infrastructure settings"
  type = object({
    account_email_prod_shared = string
  })
}

variable "workloads_settings" {
  description = "Workloads settings"
  type = map(object({
    account_email_prod = string
    account_email_test = string
  }))
}
