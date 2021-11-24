terraform {
  experiments = [module_variable_optional_attrs]
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3"
    }
  }
  required_version = "~> 1"
}

provider "github" {
  owner = local.conf.owner
}

locals {
  conf = defaults(var.conf, {
    repositories = {
      delete_branch_on_merge = true
      license                = "apache-2.0"
      visibility             = "private"
      vulnerability_alerts   = true
    }
  })
  repository_hooks = { for hook in flatten([
    for _, workflow in var.workflows_info : [
      for _, repo in github_repository.main : {
        name          = workflow.name
        repo          = repo.name
        webhook_token = workflow.webhook_token
        webhook_url   = workflow.webhook_url
      } if contains(repo.topics == null ? [] : repo.topics, workflow.name)
    ]
    ]) : "${hook.repo}:${hook.name}" => hook
  }
}

resource "github_branch_protection" "main" {
  for_each = { for repo in github_repository.main : repo.name => repo if repo.visibility == "public" }

  allows_deletions       = false
  allows_force_pushes    = false
  enforce_admins         = true
  pattern                = "main"
  push_restrictions      = []
  repository_id          = each.value.name
  require_signed_commits = true

  # required_pull_request_reviews {
  #   dismissal_restrictions = []
  #   dismiss_stale_reviews  = true
  # }

  required_status_checks {
    contexts = []
    strict   = true
  }
}

resource "github_repository" "main" {
  for_each = local.conf.repositories

  delete_branch_on_merge = each.value.delete_branch_on_merge
  description            = each.value.description
  license_template       = each.value.license
  name                   = each.key
  topics                 = each.value.topics
  visibility             = each.value.visibility
  vulnerability_alerts   = each.value.vulnerability_alerts

  lifecycle {
    ignore_changes  = [etag]
    prevent_destroy = true
  }
}

resource "github_repository_webhook" "main" {
  # for each workflow filter repositories with that tag
  for_each = local.repository_hooks

  active     = true
  events     = ["push"]
  repository = each.value.repo

  configuration {
    url          = each.value.webhook_url
    content_type = "json"
    secret       = each.value.webhook_token
    insecure_ssl = false
  }
}

resource "github_user_gpg_key" "main" {
  count = local.conf.gpg != null ? 1 : 0

  armored_public_key = base64decode(local.conf.gpg.public_key_base64)
}

resource "github_user_ssh_key" "main" {
  count = local.conf.ssh != null ? 1 : 0

  title = local.conf.ssh.title
  key   = base64decode(local.conf.ssh.public_key_base64)
}
