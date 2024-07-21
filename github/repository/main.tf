terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.2.3, < 7.0.0"
    }
  }

  required_version = ">= 1.9.2, < 2.0.0"
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

resource "github_repository" "repository" {
  name                   = var.repository_basics.name
  description            = "${var.repository_basics.description}${var.description_suffix}"
  homepage_url           = var.repository_basics.homepage_url
  visibility             = var.repository_basics.visibility
  has_issues             = var.repository_basics.has_issues
  has_projects           = var.repository_basics.has_projects
  has_wiki               = var.repository_basics.has_wiki
  has_downloads          = var.repository_basics.has_downloads
  is_template            = var.repository_basics.is_template
  license_template       = var.repository_basics.license_template
  topics                 = var.repository_basics.topics
  allow_auto_merge       = local.advanced_features
  allow_merge_commit     = false
  allow_rebase_merge     = false
  allow_squash_merge     = true
  allow_update_branch    = true
  delete_branch_on_merge = true
  gitignore_template     = "VisualStudio"
  vulnerability_alerts   = true
  archive_on_destroy     = true

  dynamic "template" {
    for_each = var.repository_basics.template != null ? [1] : []
    content {
      owner                = var.repository_basics.template.owner
      repository           = var.repository_basics.template.repository
      include_all_branches = false
    }
  }

  /*security_and_analysis {
    advanced_security {
      status = "enabled"
    }
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }*/
}

resource "github_actions_repository_permissions" "repository_actions_permissions" {
  repository = github_repository.repository.name

  enabled         = true
  allowed_actions = var.repository_basics.visibility == "public" ? "selected" : "all"

  dynamic "allowed_actions_config" {
    for_each = var.repository_basics.visibility == "public" ? [1] : []
    content {
      github_owned_allowed = true
      verified_allowed     = true
      patterns_allowed     = ["amilochau/github-actions/*"]
    }
  }
}

resource "github_issue_labels" "repository_issue_labels" {
  repository = github_repository.repository.name

  dynamic "label" {
    for_each = local.labels
    content {
      name        = label.key
      color       = label.value.color
      description = label.value.description
    }
  }
}

resource "github_repository_environment" "repository_environment" {
  for_each = local.advanced_features ? var.repository_environments : {}

  repository  = github_repository.repository.name
  environment = each.key

  deployment_branch_policy {
    protected_branches     = each.value.protected_branches_only
    custom_branch_policies = !each.value.protected_branches_only
  }

  reviewers {
    users = each.value.reviewers_ids
  }
}

resource "github_branch_protection" "repository_branch_protection" {
  count = local.advanced_features ? 1 : 0

  repository_id                   = github_repository.repository.name
  pattern                         = "main"
  enforce_admins                  = false
  require_conversation_resolution = true
  allows_deletions                = false # Applies to everybody (including administrators)
  allows_force_pushes             = false # Applies to everybody (including administrators)

  required_status_checks {
    strict = true
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true # To force review by code owners
    require_last_push_approval      = false
    required_approving_review_count = 0 # To enable admin to complete its own PR
  }
}
