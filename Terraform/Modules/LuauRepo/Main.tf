resource "github_branch_protection" "main" {
  repository_id = var.repository
  pattern       = "main"

  required_status_checks {
    strict = true

    contexts = concat(var.main_checks, var.extra_main_checks)
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 0
  }

  enforce_admins = true

  allows_deletions    = false
  allows_force_pushes = false
}

resource "github_branch_protection" "release" {
  count = var.has_release_branch ? 1 : 0

  repository_id = var.repository
  pattern       = "release"

  required_status_checks {
    strict = true

    contexts = concat(var.release_checks, var.extra_release_checks)
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 0
  }

  enforce_admins = true

  allows_deletions    = false
  allows_force_pushes = false
}
