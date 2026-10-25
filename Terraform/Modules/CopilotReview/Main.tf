# Manages a repository's Copilot code review effort level. The GitHub provider has no
# resource for it, so this talks to the REST endpoint through the gh CLI, which reads
# GITHUB_TOKEN like the provider does and sends a proper JSON body.
#
# The update resource sets the effort when it's created and whenever the repository or
# desired level changes, so a normal apply settles in one pass. Terraform can't read the
# setting back into state, so changes made outside Terraform are reported instead of being
# fixed silently. Every plan runs the check below, which warns when the repo has drifted
# and names the resource to replace to restore it.

locals {
  settings_path = "repos/${var.repository}/copilot/code-review/settings"
}

resource "terraform_data" "update" {
  triggers_replace = [var.repository, var.review_effort]

  # The repository and effort are validated in Variables.tf, so they can't inject shell
  # syntax into this command.
  provisioner "local-exec" {
    command = "gh api --method PATCH ${local.settings_path} -f review_effort=${var.review_effort} --silent"
  }
}

# Reading inside a check block means a failed read (for example, a repository that doesn't
# exist yet) only produces a warning instead of stopping the plan.
check "review_effort" {
  data "external" "current" {
    program = ["gh", "api", local.settings_path, "--jq", "{configured: (.review_effort.configured // \"unset\")}"]
  }

  assert {
    condition     = data.external.current.result.configured == var.review_effort
    error_message = "Copilot review effort for \"${var.repository}\" is \"${data.external.current.result.configured}\" instead of \"${var.review_effort}\". Restore it by applying with -replace on this module's terraform_data.update resource."
  }
}
