module "repo" {
  source     = "../LuauRepo"
  repository = var.repository

  main_checks = [
    "Check .luaurc format",
    "Check changelog format",
    "Check file headers",
    "Check for tabs",
    "Check formatting",
    "Check JSON format",
    "Check rokit.toml format",
    "Check wally.toml format",
    "Run tests",
    "Static analysis",
    "Validate branch name",
  ]

  release_checks = [
    "Check formatting",
    "Check JSON format",
    "Run tests",
    "Static analysis",
    "Validate PR title",
    "Validate version",
    "Verify diff matches main",
  ]

  extra_main_checks    = var.extra_main_checks
  extra_release_checks = var.extra_release_checks
}
