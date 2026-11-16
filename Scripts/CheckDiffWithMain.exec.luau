#!/usr/bin/env -S lune run

--[[

CheckDiffWithMain.exec

Fetches "main" from "origin" and requires the checked-out commit to have exactly the same
tree. Relies on the exit status of "git diff --quiet", so binary changes count and large
diffs are never loaded into memory.

[Usage] ./Submodules/luau-cicd/Scripts/CheckDiffWithMain.exec.luau

--]]

const Fail = require("./Helpers/Fail.func")
const process = require("@lune/process")

const CheckDiffWithMain = {}

function CheckDiffWithMain.exec()
    if #process.args ~= 0 then
        Fail("[Usage] CheckDiffWithMain.exec.luau")
    end

    const fetchResult = process.exec("git", { "fetch", "origin", "main" }, { stdio = "inherit" })
    if not fetchResult.ok then
        Fail(`Could not fetch "main" from "origin".`)
    end

    const diffResult = process.exec("git", { "diff", "--quiet", "origin/main", "HEAD", "--" })
    if diffResult.code == 1 then
        process.exec("git", { "diff", "--stat", "origin/main", "HEAD", "--" }, { stdio = "inherit" })
        Fail("PR branch has changes that differ from main. The release branch must contain exactly what is in main.")
    elseif not diffResult.ok then
        Fail(`Could not compare "HEAD" with "origin/main".`)
    end

    print("PR branch matches main exactly.")
end

CheckDiffWithMain.exec()
