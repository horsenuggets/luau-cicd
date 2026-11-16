#!/usr/bin/env -S lune run

--[[

CreateGitHubRelease.exec

Publishes a GitHub release for an existing tag with the given notes file and any number
of assets. Every asset must exist and be nonempty, and ZIP assets must pass an integrity
check, before anything is published.

[Usage] ./Submodules/luau-cicd/Scripts/CreateGitHubRelease.exec.luau <tag> <notes> [...]

--]]

const Fail = require("./Helpers/Fail.func")
const IsReleaseVersion = require("./Helpers/IsReleaseVersion.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const CreateGitHubRelease = {}

const function isNonemptyFile(path: string): boolean
    return fs.isFile(path) and fs.metadata(path).size > 0
end

function CreateGitHubRelease.exec()
    if #process.args < 2 then
        Fail("[Usage] CreateGitHubRelease.exec.luau <tag> <notes> [assets...]")
    end

    const tag = process.args[1]
    const notesPath = process.args[2]
    const assets = table.move(process.args, 3, #process.args, 1, {})

    if not IsReleaseVersion(tag) then
        Fail(`Invalid release tag "{tag}".`)
    end

    if not isNonemptyFile(notesPath) then
        Fail(`The release notes file "{notesPath}" must exist and be nonempty.`)
    end

    for _, asset in assets do
        if not isNonemptyFile(asset) then
            Fail(`Missing or empty release asset "{asset}".`)
        end
        -- Prefix relative paths so unzip never reads a leading hyphen as an option.
        const unzipPath = if string.sub(asset, 1, 1) == "/" then asset else `./{asset}`
        if string.lower(string.sub(asset, -4)) == ".zip" and not process.exec("unzip", { "-tq", unzipPath }).ok then
            Fail(`The release asset "{asset}" is not a valid ZIP archive.`)
        end
    end

    -- End option parsing so an asset named like a flag is uploaded instead of interpreted.
    const ghArgs = { "release", "create", tag, "--verify-tag", "--title", tag, "--notes-file", notesPath, "--" }
    for _, asset in assets do
        table.insert(ghArgs, asset)
    end

    if not process.exec("gh", ghArgs, { stdio = "inherit" }).ok then
        Fail(`Could not create the GitHub release "{tag}".`)
    end

    const assetLabel = if #assets == 1 then "1 asset" else `{#assets} assets`
    print(`Created the GitHub release "{tag}" with {assetLabel}.`)
end

CreateGitHubRelease.exec()
