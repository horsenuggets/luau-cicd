variable "repository" {
  description = "GitHub repository name"
  type        = string
}

variable "extra_main_checks" {
  description = "Additional required checks for main"
  type        = list(string)
  default     = []
}

variable "extra_release_checks" {
  description = "Additional required checks for release"
  type        = list(string)
  default     = []
}
