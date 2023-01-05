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
    reviewers_ids = optional(set(number), [])
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

locals {
  advanced_features = var.repository_basics.visibility == "public"
}

locals {
  labels = {
    breaking = {
      color       = "FFC107",
      description = "Breaking change"
    },
    enhancement = {
      color       = "4CAF50",
      description = "New feature or request"
    },
    bug = {
      color       = "FF5252",
      description = "Something isn't working"
    },
    minor = {
      color       = "424242",
      description = "Minor change"
    },
    documentation = {
      color       = "2196F3",
      description = "Improvements or additions to documentation"
    },
    "good first issue" = {
      color       = "1976D2",
      description = "Good for newcomers"
    }
  }
}
