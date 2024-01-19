variable "account_name" {
  description = "Account name"
  type = string
}

variable "account_email" {
  description = "Account email"
  type = string

  validation {
    condition = length(var.account_email) >= 3 && length(var.account_email) <= 64
    error_message = "Account email must use between 3 and 64 characters"
  }
}

variable "account_parent_id" {
  description = "Account parent ID"
  type = string
  default = null
}

variable "account_iam_assignments" {
  description = "Account IAM assignments"
  type = map(object({
    permission_set_arn = string
    principal_id = string
    principal_type = string
  }))
  default = {}
}
