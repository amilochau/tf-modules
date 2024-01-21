variable "organization_full_name" {
  description = "Organization long name"
  type        = string
}

variable "ou_organization_id" {
  description = "OU organization ID"
  type        = string
}

variable "workloads_settings" {
  description = "Workloads settings"
  type = map(object({
    account_email_prod = string
    account_email_test = string
  }))
}

variable "default_account_iam_assignments" {
  description = "Default account IAM assignments"
  type = map(object({
    permission_set_arn = string
    principal_id       = string
    principal_type     = optional(string, "GROUP")
  }))
  default = {}
}
