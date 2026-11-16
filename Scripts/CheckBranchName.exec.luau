#!/usr/bin/env -S lune run

--[[

CheckBranchName.exec

Requires a branch name in the "<prefix>/<name>" format, with both parts in lowercase
kebab-case. Pass the branch through an environment variable in workflows so that GitHub
expressions are never interpolated into the shell.

[Usage] ./Submodules/luau-cicd/Scripts/CheckBranchName.exec.luau "$BRANCH"

--]]

const Fail = require("./Helpers/Fail.func")
const process = require("@lune/process")

const CheckBranchName = {}

const function isKebabCase(part: string): boolean
    -- Luau patterns lack grouping, so check the shape piece by piece.
    return string.match(part, "^[a-z0-9%-]+$") ~= nil
        and string.sub(part, 1, 1) ~= "-"
        and string.sub(part, -1) ~= "-"
        and string.find(part, "--", 1, true) == nil
end

function CheckBranchName.exec()
    if #process.args ~= 1 then
        Fail("[Usage] CheckBranchName.exec.luau <branch>")
    end

    const branch = process.args[1]
    print(`Checking branch name "{branch}".`)

    const prefix, name = string.match(branch, "^([^/]*)/([^/]*)$")
    if not prefix or not isKebabCase(prefix) or not isKebabCase(name) then
        Fail(`Branch name must be "<prefix>/<name>" in lowercase kebab-case (e.g., "feature/my-new-feature").`)
    end

    print("Branch name is valid.")
end

CheckBranchName.exec()
