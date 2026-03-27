# Standard Luau packages (horsenuggets)
# These all use the standard CI checks from luau-cicd.

module "assetfile" {
  source         = "./modules/luau-repo"
  repository     = "assetfile"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "chalk-luau" {
  source         = "./modules/luau-repo"
  repository     = "chalk-luau"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "commandline-luau" {
  source         = "./modules/luau-repo"
  repository     = "commandline-luau"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "discord-luau-fork" {
  source         = "./modules/luau-repo"
  repository     = "discord-luau-fork"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "dotenv-luau" {
  source         = "./modules/luau-repo"
  repository     = "dotenv-luau"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "hashlib" {
  source         = "./modules/luau-repo"
  repository     = "hashlib"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "luau-cicd" {
  source             = "./modules/luau-repo"
  repository         = "luau-cicd"
  main_checks        = var.standard_main_checks
  release_checks     = var.standard_release_checks
  has_release_branch = false
}

module "luau-futures" {
  source         = "./modules/luau-repo"
  repository     = "luau-futures"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "luau-gl" {
  source         = "./modules/luau-repo"
  repository     = "luau-gl"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "luau-markdown-renderer" {
  source         = "./modules/luau-repo"
  repository     = "luau-markdown-renderer"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "lune-pm" {
  source         = "./modules/luau-repo"
  repository     = "lune-pm"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "testable" {
  source         = "./modules/luau-repo"
  repository     = "testable"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

# Custom repos with additional checks

module "luauproject-cli" {
  source         = "./modules/luau-repo"
  repository     = "luauproject-cli"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
  extra_main_checks = [
    "Test install on linux",
    "Test install on macos",
    "Test install on windows",
  ]
  extra_release_checks = [
    "Test install on linux",
    "Test install on macos",
    "Test install on windows",
  ]
}
