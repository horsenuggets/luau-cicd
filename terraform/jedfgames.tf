# Standard Luau packages (jedfgames)
# These all use the standard CI checks from luau-cicd.

module "bloxdrive" {
  source = "./modules/luau-repo"
  providers = {
    github = github.jedfgames
  }
  repository     = "bloxdrive"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "slopkit" {
  source = "./modules/luau-repo"
  providers = {
    github = github.jedfgames
  }
  repository     = "slopkit"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "tower-defense-maker" {
  source = "./modules/luau-repo"
  providers = {
    github = github.jedfgames
  }
  repository     = "tower-defense-maker"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "tower-of-falling-brainrots" {
  source = "./modules/luau-repo"
  providers = {
    github = github.jedfgames
  }
  repository     = "tower-of-falling-brainrots"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}
