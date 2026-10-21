terraform {
  # Import blocks in Imports.tf require Terraform 1.5 or newer.
  required_version = ">= 1.5"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = "horsenuggets"
}

provider "github" {
  alias = "jedfgames"
  owner = "jedfgames"
}
