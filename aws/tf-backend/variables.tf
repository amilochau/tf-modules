variable "conventions" {
  description = "Conventions to use"
  type = object({
    application_name = string
    host_name        = string
    temporary        = optional(bool, false)
  })

  validation {
    condition     = length(var.conventions.application_name) >= 2 && length(var.conventions.application_name) <= 12 && can(regex("^[a-z]+$", var.conventions.application_name))
    error_message = "Application name must use between 2 and 12 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.conventions.host_name) >= 3 && length(var.conventions.host_name) <= 8 && can(regex("^[a-z0-9]+$", var.conventions.host_name))
    error_message = "Host name must use between 2 and 8 characters, only lowercase letters and numbers"
  }
}

variable "s3_bucket_name_suffix" {
  description = "Suffix used for the S3 bucket name - as the name is global"
  type        = string
  default     = ""

  validation {
    condition     = var.s3_bucket_name_suffix == "" || length(var.s3_bucket_name_suffix) <= 8 && can(regex("^[a-z0-9]+$", var.s3_bucket_name_suffix))
    error_message = "S3 bucket name suffix must use less than 8 characters, only lowercase letters and numbers"
  }
}
