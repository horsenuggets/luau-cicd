# Standard CI checks for Luau packages (main branch)
# These must match the job names in Templates/workflows/ci.yml
variable "standard_main_checks" {
  description = "Required CI checks for PRs to main"
  type        = list(string)
  default = [
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
}

# Standard release checks for Luau packages (release branch)
# These must match the job names in Templates/workflows/release-checks.yml
variable "standard_release_checks" {
  description = "Required checks for PRs to release"
  type        = list(string)
  default = [
    "Check formatting",
    "Check JSON format",
    "Run tests",
    "Static analysis",
    "Validate PR title",
    "Validate version",
    "Verify diff matches main",
    "Verify Wally auth",
  ]
}

# Release checks for private packages that don't publish to Wally
variable "standard_release_checks_no_wally" {
  description = "Required checks for PRs to release (no Wally auth)"
  type        = list(string)
  default = [
    "Check formatting",
    "Check JSON format",
    "Run tests",
    "Static analysis",
    "Validate PR title",
    "Validate version",
    "Verify diff matches main",
  ]
}
