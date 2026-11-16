#!/usr/bin/env -S lune run

--[[

CreateGitTag.exec

Creates a release tag at "HEAD" and pushes it to "origin". Rejects anything other than a
release version (MAJOR.MINOR.PATCH with an optional prerelease suffix) before touching
Git, so a malformed tag can never reach the remote.

[Usage] ./Submodules/luau-cicd/Scripts/CreateGitTag.exec.luau "$VERSION_TAG"

--]]

const Fail = require("./Helpers/Fail.func")
const IsReleaseVersion = require("./Helpers/IsReleaseVersion.func")
const process = require("@lune/process")

const CreateGitTag = {}

function CreateGitTag.exec()
    if #process.args ~= 1 then
        Fail("[Usage] CreateGitTag.exec.luau <tag>")
    end

    const tag = process.args[1]
    if not IsReleaseVersion(tag) then
        Fail(`Invalid release tag "{tag}".`)
    end

    if not process.exec("git", { "tag", tag }, { stdio = "inherit" }).ok then
        Fail(`Could not create the tag "{tag}".`)
    end

    if not process.exec("git", { "push", "origin", `refs/tags/{tag}` }, { stdio = "inherit" }).ok then
        Fail(`Could not push the tag "{tag}" to "origin".`)
    end

    print(`Created and pushed the tag "{tag}".`)
end

CreateGitTag.exec()
