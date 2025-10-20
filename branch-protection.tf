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

  # Status checks comentados para evitar deadlock circular
  # El workflow no puede pasar si requiere que pase para hacer push
  # 
  # required_status_checks {
  #   strict = true
  #   contexts = [
  #     "Backend CI/CD",
  #     "Worker CI/CD",
  #     "Frontend CI/CD"
  #   ]
  # }

  # Protección básica: no force push, no delete

  enforce_admins                  = false
  require_conversation_resolution = false
  allows_force_pushes             = false
  allows_deletions                = false
}

