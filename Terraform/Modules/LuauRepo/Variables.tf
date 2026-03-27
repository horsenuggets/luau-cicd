variable "repository" {
  description = "GitHub repository name"
  type        = string
}

variable "main_checks" {
  description = "Required status checks for PRs to main"
  type        = list(string)
}

variable "release_checks" {
  description = "Required status checks for PRs to release"
  type        = list(string)
}

variable "extra_main_checks" {
  description = "Additional required checks for main (appended to main_checks)"
  type        = list(string)
  default     = []
}

variable "extra_release_checks" {
  description = "Additional required checks for release (appended to release_checks)"
  type        = list(string)
  default     = []
}

variable "has_release_branch" {
  description = "Whether the repo has a release branch"
  type        = bool
  default     = true
}
