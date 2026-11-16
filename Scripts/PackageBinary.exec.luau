#!/usr/bin/env -S lune run

--[[

PackageBinary.exec

Packages "Build/<name>" (or "Build/<name>.exe" on Windows) as a Rokit-compatible ZIP named
"Build/<name>-<os>-<x64|arm64>.zip". Recreates the archive on every run so stale entries
never survive, and writes its path to "GITHUB_OUTPUT" as "archive" when that is set.

[Usage] ./Submodules/luau-cicd/Scripts/PackageBinary.exec.luau <name> <target>

--]]

const Fail = require("./Helpers/Fail.func")
const GetReleaseAssetSuffix = require("./Helpers/GetReleaseAssetSuffix.func")
const WriteGitHubOutputs = require("./Helpers/WriteGitHubOutputs.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const BUILD_DIR = "Build"

const PackageBinary = {}

function PackageBinary.exec()
    if #process.args ~= 2 then
        Fail("[Usage] PackageBinary.exec.luau <name> <target>")
    end

    const name = process.args[1]
    const target = process.args[2]

    if not string.match(name, "^[%w][%w_%-]*$") then
        Fail(`Invalid binary name "{name}".`)
    end

    const suffix, suffixError = GetReleaseAssetSuffix(target)
    if not suffix then
        Fail(suffixError :: string)
    end

    const binary = if string.sub(target, 1, 8) == "windows-" then `{name}.exe` else name
    const binaryPath = `{BUILD_DIR}/{binary}`
    if not fs.isFile(binaryPath) or fs.metadata(binaryPath).size == 0 then
        Fail(`Missing or empty executable "{binaryPath}".`)
    end

    const archive = `{name}-{suffix}.zip`
    const archivePath = `{BUILD_DIR}/{archive}`
    if fs.isFile(archivePath) then
        fs.removeFile(archivePath)
    end

    if not process.exec("chmod", { "+x", binaryPath }).ok then
        Fail(`Could not make "{binaryPath}" executable.`)
    end

    if not process.exec("zip", { "-q", archive, binary }, { cwd = BUILD_DIR }).ok then
        Fail(`Could not create "{archivePath}".`)
    end

    const outputPath = process.env.GITHUB_OUTPUT
    if outputPath and outputPath ~= "" then
        WriteGitHubOutputs(outputPath, { archive = archivePath })
    end

    print(`Packaged "{binaryPath}" into "{archivePath}".`)
end

PackageBinary.exec()
