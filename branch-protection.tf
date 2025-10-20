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

  # Sin PR reviews = bot puede hacer push
  # Pero CI checks SIEMPRE obligatorios

  enforce_admins                  = false
  require_conversation_resolution = false # sin PRs, no hay conversaciones
  allows_force_pushes             = false
  allows_deletions                = false
}

