terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  owner = "RDSDeveloper"
}

resource "github_branch_protection" "main" {
  repository_id = "k8s-training"
  pattern       = "main"

  required_status_checks {
    strict = true
    contexts = [
      "Backend CI/CD",
      "Worker CI/CD",
      "Frontend CI/CD"
    ]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
    required_approving_review_count = 2
  }

  # false para permitir que github-actions bot haga push
  enforce_admins                  = false
  require_conversation_resolution = true
  allows_force_pushes             = false
  allows_deletions                = false
}

