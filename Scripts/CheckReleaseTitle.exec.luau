#!/usr/bin/env -S lune run

--[[

CheckReleaseTitle.exec

Requires a release PR title to be exactly "Release X.Y.Z", optionally with a SemVer
prerelease suffix like "-beta.6", and nothing before or after it. Pass the title through
an environment variable in workflows so GitHub expressions never reach the shell.

[Usage] ./Submodules/luau-cicd/Scripts/CheckReleaseTitle.exec.luau "$TITLE"

--]]

const Fail = require("./Helpers/Fail.func")
const IsReleaseVersion = require("./Helpers/IsReleaseVersion.func")
const process = require("@lune/process")

const CheckReleaseTitle = {}

function CheckReleaseTitle.exec()
    if #process.args ~= 1 then
        Fail("[Usage] CheckReleaseTitle.exec.luau <title>")
    end

    const title = process.args[1]
    print(`Checking PR title "{title}".`)

    const version = string.match(title, "^Release (.*)$")
    if not version or not IsReleaseVersion(version) then
        Fail(`PR title must be exactly "Release X.Y.Z" or "Release X.Y.Z-suffix" (e.g., "Release 1.2.3").`)
    end

    print("PR title is valid.")
end

CheckReleaseTitle.exec()
