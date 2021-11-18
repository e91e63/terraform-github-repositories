terraform {
  experiments = [module_variable_optional_attrs]
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4"
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
    }
  })
}
resource "github_repository" "main" {
  for_each = local.conf.repositories

  delete_branch_on_merge = each.value.delete_branch_on_merge
  description            = each.value.description
  #   license_template = each.value.license
  name       = each.key
  visibility = each.value.visibility

  #   lifecycle {
  #     prevent_destroy = true
  #   }
}
