# Standard Luau packages (horsenuggets)
# These all use the standard CI checks from luau-cicd.

module "assetfile" {
  source         = "./Modules/LuauRepo"
  repository     = "assetfile"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "chalk-luau" {
  source         = "./Modules/LuauRepo"
  repository     = "chalk-luau"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "commandline-luau" {
  source         = "./Modules/LuauRepo"
  repository     = "commandline-luau"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "discord-luau-fork" {
  source         = "./Modules/LuauRepo"
  repository     = "discord-luau-fork"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "dotenv-luau" {
  source         = "./Modules/LuauRepo"
  repository     = "dotenv-luau"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "hashlib" {
  source         = "./Modules/LuauRepo"
  repository     = "hashlib"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "luau-cicd" {
  source             = "./Modules/LuauRepo"
  repository         = "luau-cicd"
  main_checks        = var.standard_main_checks
  release_checks     = var.standard_release_checks
  has_release_branch = false
}

module "luau-futures" {
  source         = "./Modules/LuauRepo"
  repository     = "luau-futures"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "luau-gl" {
  source         = "./Modules/LuauRepo"
  repository     = "luau-gl"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "luau-markdown-renderer" {
  source         = "./Modules/LuauRepo"
  repository     = "luau-markdown-renderer"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "lune-pm" {
  source         = "./Modules/LuauRepo"
  repository     = "lune-pm"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

module "testable" {
  source         = "./Modules/LuauRepo"
  repository     = "testable"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks
}

# Custom repos with additional checks

module "luauproject-cli" {
  source         = "./Modules/LuauRepo"
  repository     = "luauproject-cli"
  main_checks    = var.standard_main_checks
  release_checks = var.standard_release_checks_no_wally
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
