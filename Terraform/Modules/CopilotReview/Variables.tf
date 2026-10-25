variable "repository" {
  description = "Full repository name in owner/name form."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.repository))
    error_message = "The repository must be in owner/name form using only letters, digits, \".\", \"_\", and \"-\"."
  }
}

variable "review_effort" {
  description = "Copilot code review effort level for the repository."
  type        = string
  default     = "lite"

  validation {
    condition     = contains(["lite", "balanced"], var.review_effort)
    error_message = "The review effort must be \"lite\" or \"balanced\"."
  }
}
