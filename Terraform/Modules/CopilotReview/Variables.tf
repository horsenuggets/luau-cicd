variable "repository" {
  description = "Full repository name in owner/name form. Pass a literal string, not a resource attribute, so the effort check can run at plan time."
  type        = string
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
