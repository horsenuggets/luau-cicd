# Luau packages and games (jedfgames)
# Packages use the standard CI checks from luau-cicd. Games override the lists that differ.

module "bloxdrive" {
  source = "./Modules/LuauRepo"
  providers = {
    github = github.jedfgames
  }
  repository     = "bloxdrive"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

# Games have their own CI and release checks rather than the package template's, so their
# check lists must match the job names in each game's .github/workflows/ci.yml and
# release-checks.yml.
module "eat-while-mom-isnt-looking" {
  source = "./Modules/LuauRepo"
  providers = {
    github = github.jedfgames
  }
  repository = "eat-while-mom-isnt-looking"
  main_checks = [
    "Check file headers",
    "Check formatting",
    "Run tests",
    "Static analysis",
    "Validate branch name",
  ]
  release_checks = var.game_release_checks
}

module "slopkit" {
  source = "./Modules/LuauRepo"
  providers = {
    github = github.jedfgames
  }
  repository     = "slopkit"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "tower-defense-maker" {
  source = "./Modules/LuauRepo"
  providers = {
    github = github.jedfgames
  }
  repository     = "tower-defense-maker"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "tower-of-falling-brainrots" {
  source = "./Modules/LuauRepo"
  providers = {
    github = github.jedfgames
  }
  repository        = "tower-of-falling-brainrots"
  main_checks       = var.standard_main_checks
  extra_main_checks = ["Check version match"]
  release_checks    = var.game_release_checks
}
