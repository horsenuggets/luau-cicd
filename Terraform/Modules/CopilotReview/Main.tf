# Manages a repository's Copilot code review effort level. The GitHub provider has no
# resource for it, so this talks to the REST endpoint through the gh CLI, which reads
# GITHUB_TOKEN like the provider does and runs the same way on every platform.
#
# Every plan reads the current setting. The update resource only exists while the setting
# differs from the desired level, so a repo that drifts shows up as "1 to add" and is
# corrected on apply. The next plan then removes the update resource again, which makes no
# API call.

locals {
  settings_path = "repos/${var.repository}/copilot/code-review/settings"
}

data "external" "current" {
  program = ["gh", "api", local.settings_path, "--jq", "{configured: (.review_effort.configured // \"unset\")}"]
}

resource "terraform_data" "update" {
  count = data.external.current.result.configured == var.review_effort ? 0 : 1

  triggers_replace = [var.repository, var.review_effort]

  provisioner "local-exec" {
    command = "gh api --method PATCH ${local.settings_path} -f review_effort=${var.review_effort} --silent"
  }
}
