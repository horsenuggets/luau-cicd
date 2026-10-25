# These repos already had a "Copilot Code Review" ruleset created by hand before the
# LuauRepo module managed one. Ruleset names must be unique per repo, so we adopt the
# existing rulesets instead of creating duplicates. These blocks are no-ops once the
# rulesets are in state and can be removed after the next apply.

import {
  id = "luau-gl:14186878"
  to = module.luau-gl.github_repository_ruleset.copilot_code_review
}

import {
  id = "bloxdrive:13797447"
  to = module.bloxdrive.github_repository_ruleset.copilot_code_review
}

import {
  id = "slopkit:13762043"
  to = module.slopkit.github_repository_ruleset.copilot_code_review
}

import {
  id = "tower-defense-maker:13659707"
  to = module.tower-defense-maker.github_repository_ruleset.copilot_code_review
}

import {
  id = "tower-of-falling-brainrots:13764603"
  to = module.tower-of-falling-brainrots.github_repository_ruleset.copilot_code_review
}

# eat-while-mom-isnt-looking existed with hand-made settings and branch protection before
# it was added here, so we adopt them instead of creating new ones. These blocks are also
# no-ops once applied.

import {
  id = "eat-while-mom-isnt-looking"
  to = module.eat-while-mom-isnt-looking.github_repository.repo
}

import {
  id = "eat-while-mom-isnt-looking:main"
  to = module.eat-while-mom-isnt-looking.github_branch_protection.main
}

import {
  id = "eat-while-mom-isnt-looking:release"
  to = module.eat-while-mom-isnt-looking.github_branch_protection.release[0]
}
