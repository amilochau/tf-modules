terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 5.18.0, < 6.0.0"
    }
  }

  required_version = ">= 1.3.0"
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
  allowed_actions = "selected"
  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
    patterns_allowed     = []
  }
}

resource "github_issue_label" "repository_issue_label" {
  for_each = local.labels

  repository  = github_repository.repository.name
  name        = each.key
  description = each.value.description
  color       = each.value.color
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

resource "github_branch_protection_v3" "repository_branch_protection" {
  repository                      = github_repository.repository.name
  branch                          = "main"
  enforce_admins                  = false
  require_conversation_resolution = true

  required_status_checks {
    strict = true
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true # To force review by code owners
    required_approving_review_count = 0    # To enable admin to complete its own PR
  }

  /*repository_id                   = github_repository.repository.name
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
  }*/
}

resource "github_repository_file" "file_readme" {
  repository = github_repository.repository.name
  branch     = "main"
  file       = "README.md"
  content = templatefile("${path.module}/files/README.md", {
    repository_name = github_repository.repository.name
  })

  lifecycle {
    ignore_changes = [
      content
    ]
  }
}

resource "github_repository_file" "file_codeowners" {
  repository          = github_repository.repository.name
  branch              = "main"
  file                = "./.github/CODEOWNERS"
  content             = file("${path.module}/files/CODEOWNERS")
  overwrite_on_create = true
}

resource "github_repository_file" "file_release" {
  repository          = github_repository.repository.name
  branch              = "main"
  file                = "./.github/release.yml"
  content             = file("${path.module}/files/release.yml")
  overwrite_on_create = true
}

resource "github_repository_file" "file_workflow_dependency_review" {
  count = var.workflows.enable_dependency_review ? 1 : 0

  repository          = github_repository.repository.name
  branch              = "main"
  file                = "./.github/workflows/dependency-review.yml"
  content             = file("${path.module}/files/workflows/dependency-review.yml")
  overwrite_on_create = true
}

resource "github_repository_file" "file_workflow_clean" {
  count = var.workflows.enable_clean ? 1 : 0

  repository          = github_repository.repository.name
  branch              = "main"
  file                = "./.github/workflows/clean.yml"
  content             = file("${path.module}/files/workflows/clean.yml")
  overwrite_on_create = true
}
