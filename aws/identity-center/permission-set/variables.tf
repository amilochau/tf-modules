variable "identity_center_arn" {
  description = "Identity center ARN"

}

variable "permission_set" {
  description = "Permission set settings"
  type = object({
    name                = string
    description         = string
    session_duration    = string
    managed_policy_arns = list(string)
  })
}
