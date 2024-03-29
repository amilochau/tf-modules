variable "context" {
  description = "Context to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
    temporary         = optional(bool, false)
  })

  validation {
    condition     = length(var.context.organization_name) >= 3 && length(var.context.organization_name) <= 5 && can(regex("^[a-z]+$", var.context.organization_name))
    error_message = "Organization name must use between 3 and 5 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.context.application_name) >= 2 && length(var.context.application_name) <= 12 && can(regex("^[a-z]+$", var.context.application_name))
    error_message = "Application name must use between 2 and 12 characters, only lowercase letters"
  }

  validation {
    condition     = length(var.context.host_name) >= 3 && length(var.context.host_name) <= 8 && can(regex("^[a-z0-9]+$", var.context.host_name))
    error_message = "Host name must use between 2 and 8 characters, only lowercase letters and numbers"
  }
}

variable "repository_basics" {
  description = "Basic settings for repository"
  type = object({
    name             = string
    description      = string
    homepage_url     = optional(string, "")
    visibility       = optional(string, "private")
    has_issues       = optional(bool, true)
    has_projects     = optional(bool, false)
    has_wiki         = optional(bool, false)
    has_downloads    = optional(bool, true)
    is_template      = optional(bool, false)
    license_template = optional(string, "mit")
    topics           = set(string)

    template = optional(object({
      owner      = string
      repository = string
    }), null)
  })
}

variable "repository_environments" {
  description = "Environments settings for repository"
  type = map(object({
    protected_branches_only = optional(bool, true)
    reviewers_ids           = optional(set(number), [])
  }))
  default = {}
}

variable "description_suffix" {
  description = "Description suffix to add to repository description"
  type        = string
  default     = " ✅"
}
