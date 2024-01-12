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
    infrastructure = object({
      account_email_prod_shared = string
    })
    workloads = map(object({
      account_email_prod = string
      account_email_test = string
    }))
  }))
}
