terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0, < 7.0.0"
    }
  }

  required_version = ">= 1.8.0, < 2.0.0"
}

resource "github_organization_settings" "organization_settings" {
  name                                                     = var.github_organization_settings.name
  billing_email                                            = var.github_organization_settings.billing_email
  blog                                                     = var.github_organization_settings.blog
  default_repository_permission                            = "none"
  dependabot_alerts_enabled_for_new_repositories           = true
  dependabot_security_updates_enabled_for_new_repositories = true
  dependency_graph_enabled_for_new_repositories            = true
  location                                                 = var.github_organization_settings.location
  has_organization_projects                                = false
  has_repository_projects                                  = false
  members_can_create_repositories                          = false
  members_can_create_public_repositories                   = false
  members_can_create_private_repositories                  = false
  members_can_create_internal_repositories                 = false
  members_can_create_pages                                 = false
  members_can_create_public_pages                          = false
  members_can_create_private_pages                         = false
  members_can_fork_private_repositories                    = false

  #company = "Test Company"
  #blog = "https://example.com"
  #email = "test@example.com"
  #description = "Test Description"
  #web_commit_signoff_required = true
  #advanced_security_enabled_for_new_repositories = false
  #secret_scanning_enabled_for_new_repositories = false
  #secret_scanning_push_protection_enabled_for_new_repositories = false
}

resource "github_actions_organization_permissions" "github_actions_organization_permissions" {
  allowed_actions      = "all" # Note: we can't select specific allowed actions with a Free plan
  enabled_repositories = "all"
}
