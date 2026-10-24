#!/usr/bin/env -S lune run

--[[

BumpVersion.exec

Bumps the version in VERSION file and syncs it to wally.toml. Pass "major", "minor", or
"patch" as an argument to bump the corresponding version component.

[Usage] ./Scripts/BumpVersion.exec.luau <major|minor|patch>

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")

const parseVersion = require("./Helpers/parseVersion")

const BumpVersion = {}

function BumpVersion.exec()
    const args = process.args
    if #args < 1 then
        print("[Usage] ./Scripts/BumpVersion.exec.luau <major|minor|patch>")
        process.exit(1)
    end

    const bumpType = string.lower(args[1])
    if bumpType ~= "major" and bumpType ~= "minor" and bumpType ~= "patch" then
        print(`Invalid bump type "{bumpType}". Must be "major", "minor", or "patch".`)
        process.exit(1)
    end

    const currentVersionString = fs.readFile("VERSION")
    local major, minor, patch = parseVersion(currentVersionString)

    if not major then
        print(`Could not parse current version "{currentVersionString}".`)
        process.exit(1)
    end

    const previousVersion = `{major}.{minor}.{patch}`
    print(`Current version is "{previousVersion}".`)

    if bumpType == "major" then
        major += 1
        minor = 0
        patch = 0
    elseif bumpType == "minor" then
        minor += 1
        patch = 0
    else
        patch += 1
    end

    const newVersion = `{major}.{minor}.{patch}`
    print(`Bumping to "{newVersion}".`)

    fs.writeFile("VERSION", newVersion .. "\n")

    print("Syncing version to wally.toml.")
    -- Resolve SyncVersion next to this script, so it's found when this runs from a
    -- consumer repo through Submodules/luau-cicd/ and not only from luau-cicd itself
    const scriptsDir = string.match(debug.info(1, "s"), "^(.*)[/\\]") or "."
    const syncResult = process.exec("lune", { "run", `{scriptsDir}/SyncVersion.exec` })
    if not syncResult.ok then
        print("Failed to sync version.")
        print(syncResult.stderr)
        process.exit(1)
    end

    print("Done.")
end

BumpVersion.exec()
