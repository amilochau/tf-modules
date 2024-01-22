variable "management_settings" {
  description = "Management settings"
  type = object({
    account_email = string
  })
}

variable "sandbox_settings" {
  description = "Sandbox settings"
  type = object({
    account_email = string
  })
}

variable "organizations_settings" {
  description = "Organizations settings"
  type = map(object({
    deployments = object({
      account_email = string
    })
    infrastructure = object({
      account_email = string
    })
    workloads = object({
      account_email_prod = string
      account_email_test = string
    })
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
