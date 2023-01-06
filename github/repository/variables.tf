variable "conventions" {
  description = "Conventions to use"
  type = object({
    organization_name = string
    application_name  = string
    host_name         = string
  })
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

variable "workflows" {
  description = "Workflows to add"
  type = object({
    enable_dependency_review = optional(bool, false)
  })
  default = {}
}

variable "description_suffix" {
  description = "Description suffix to add to repository description"
  type        = string
  default     = " ✅"
}
