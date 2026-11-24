#!/usr/bin/env -S lune run

--[[

GetReleaseInfo.exec

Writes the release version, tag, and notes file path to "GITHUB_OUTPUT". The notes are
the "CHANGELOG.md" section for the version in "VERSION", written to "RUNNER_TEMP". Fails
when the version is malformed or has no changelog notes.

[Usage] ./Submodules/luau-cicd/Scripts/GetReleaseInfo.exec.luau

--]]

const ExtractChangelog = require("./Helpers/ExtractChangelog.func")
const Fail = require("./Helpers/Fail.func")
const IsReleaseVersion = require("./Helpers/IsReleaseVersion.func")
const WriteGitHubOutputs = require("./Helpers/WriteGitHubOutputs.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const GetReleaseInfo = {}

const function requireEnv(name: string): string
    const value = process.env[name]
    if value == nil or value == "" then
        return Fail(`The "{name}" environment variable must be set.`)
    end
    return value
end

function GetReleaseInfo.exec()
    if #process.args ~= 0 then
        Fail("[Usage] GetReleaseInfo.exec.luau")
    end

    const outputPath = requireEnv("GITHUB_OUTPUT")
    const tempDir = requireEnv("RUNNER_TEMP")

    if not fs.isFile("VERSION") then
        Fail(`The "VERSION" file does not exist.`)
    end

    const version = string.match(fs.readFile("VERSION"), "^%s*(.-)%s*$") or ""
    if not IsReleaseVersion(version) then
        Fail(`Invalid release version "{version}".`)
    end

    const notes = ExtractChangelog(version)
    if not notes then
        Fail(`Missing changelog notes for "{version}".`)
    end

    const notesPath = `{tempDir}/changelog.txt`
    fs.writeFile(notesPath, `{notes}\n`)

    WriteGitHubOutputs(outputPath, {
        notes_file = notesPath,
        tag = version,
        version = version
    })

    print(`Prepared release "{version}" with notes in "{notesPath}".`)
end

GetReleaseInfo.exec()
