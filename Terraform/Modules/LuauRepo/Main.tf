resource "github_repository" "repo" {
  name = var.repository

  allow_squash_merge = true
  allow_merge_commit = false
  allow_rebase_merge = false

  delete_branch_on_merge = true

  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  lifecycle {
    ignore_changes = [
      allow_auto_merge,
      allow_update_branch,
      description,
      homepage_url,
      merge_commit_message,
      merge_commit_title,
      visibility,
      topics,
      has_downloads,
      has_issues,
      has_projects,
      has_wiki,
      archived,
      archive_on_destroy,
      vulnerability_alerts,
      pages,
      security_and_analysis,
      template,
    ]
  }
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  required_status_checks {
    strict = true

    contexts = concat(var.main_checks, var.extra_main_checks)
  }

  # The one required approval comes from Copilot, which needs "Allow Copilot to approve pull
  # requests" turned on in the repo's Copilot code review settings.
  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }

  enforce_admins = true

  allows_deletions    = false
  allows_force_pushes = false
}

# Classic branch protection can't express Copilot code review, so this ruleset layers it
# on top of the protection above. It only requests the review, and the approval
# requirement above is what blocks merges.
resource "github_repository_ruleset" "copilot_code_review" {
  name        = "Copilot Code Review"
  repository  = github_repository.repo.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = var.has_release_branch ? ["refs/heads/main", "refs/heads/release"] : ["refs/heads/main"]
      exclude = []
    }
  }

  rules {
    copilot_code_review {
      review_draft_pull_requests = false
      review_on_push             = true
    }
  }
}

resource "github_branch_protection" "release" {
  count = var.has_release_branch ? 1 : 0

  repository_id = github_repository.repo.node_id
  pattern       = "release"

  required_status_checks {
    strict = true

    contexts = concat(var.release_checks, var.extra_release_checks)
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }

  enforce_admins = true

  allows_deletions    = false
  allows_force_pushes = false
}
