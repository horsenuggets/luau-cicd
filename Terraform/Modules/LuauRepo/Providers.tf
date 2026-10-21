terraform {
  required_providers {
    github = {
      source = "integrations/github"

      # The copilot_code_review ruleset rule was added in 6.10.0.
      version = ">= 6.10.0"
    }
  }
}
