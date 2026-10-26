variable "repository" {
  description = "Full repository name in owner/name form."
  type        = string

  # The name also can't be "." or "..", which would be resolved as path segments in the API
  # path (GitHub doesn't allow those names anyway). Terraform doesn't short-circuit "&&", so
  # the split is wrapped in try() for inputs without a slash.
  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.repository)) &&
      !contains([".", ".."], try(split("/", var.repository)[1], ""))
    )
    error_message = "The repository must be in owner/name form using only letters, digits, \".\", \"_\", and \"-\", and the name can't be \".\" or \"..\"."
  }
}

variable "review_effort" {
  description = "Copilot code review effort level for the repository."
  type        = string

  validation {
    condition     = contains(["lite", "balanced"], var.review_effort)
    error_message = "The review effort must be \"lite\" or \"balanced\"."
  }
}
