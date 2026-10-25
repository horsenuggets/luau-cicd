# Manages a repository's Copilot code review effort level. The GitHub provider has no
# resource for it, so this talks to the REST endpoint through the gh CLI, which reads
# GITHUB_TOKEN like the provider does and sends a proper JSON body.
#
# Every plan reads the current setting, and the update resource's trigger is the desired
# level while the repo matches it and "drift" otherwise. A repo that drifts is replaced and
# corrected on apply. Because the stored trigger is still "drift" at that point, the next
# apply replaces it once more with a PATCH that changes nothing, and then it stays stable.

locals {
  settings_path = "repos/${var.repository}/copilot/code-review/settings"
}

data "external" "current" {
  program = ["gh", "api", local.settings_path, "--jq", "{configured: (.review_effort.configured // \"unset\")}"]
}

resource "terraform_data" "update" {
  triggers_replace = [
    var.repository,
    var.review_effort,
    data.external.current.result.configured == var.review_effort ? var.review_effort : "drift",
  ]

  # The repository and effort are validated in Variables.tf, so they can't inject shell
  # syntax into this command.
  provisioner "local-exec" {
    command = "gh api --method PATCH ${local.settings_path} -f review_effort=${var.review_effort} --silent"
  }
}
