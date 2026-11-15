#!/usr/bin/env -S lune run

--[[

EnsureProperVersionUpdate.exec

Validates that the VERSION file contains a proper semantic version and that it has been
bumped correctly since the last release tag. Compares against the most recent Git tag
(excluding 0.0.0) to determine if a valid version bump has occurred.

--]]

const ParseVersion = require("./Helpers/ParseVersion.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const EnsureProperVersionUpdate = {}

function EnsureProperVersionUpdate.exec()
    assert(fs.isFile("VERSION"), 'The "VERSION" file does not exist.')

    -- Read the current VERSION file.
    const currentVersionString = fs.readFile("VERSION")
    const currentMajor, currentMinor, currentPatch = ParseVersion(currentVersionString)

    -- Validate the current version format.
    if not currentMajor then
        print(
            `The "VERSION" file is not in MAJOR.MINOR.PATCH format. Its current content is "{string.match(
                currentVersionString,
                "^%s*(.-)%s*$"
            )}".`
        )
        process.exit(1)
    end

    print(`Current version is "{currentMajor}.{currentMinor}.{currentPatch}".`)

    -- Get the latest tag, excluding 0.0.0.
    const tagResult = process.exec("git", { "tag", "--sort=-version:refname" })

    if not tagResult.ok then
        print("Could not retrieve Git tags.")
        print("Version format is valid.")
        return
    end

    -- Find the first tag that is not 0.0.0.
    local latestTag = nil
    for tag in string.gmatch(tagResult.stdout, "[^\n]+") do
        if tag ~= "0.0.0" then
            latestTag = tag
            break
        end
    end

    if not latestTag then
        print("No previous release tags found.")
        print("Version format is valid.")
        return
    end

    print(`Latest release tag is "{latestTag}".`)

    -- Read VERSION from the tag.
    const versionAtTagResult = process.exec("git", { "show", `{latestTag}:VERSION` })

    if not versionAtTagResult.ok then
        print(`Could not read "VERSION" at tag "{latestTag}".`)
        print("Version format is valid.")
        return
    end

    const previousVersionString = versionAtTagResult.stdout
    const previousMajor, previousMinor, previousPatch = ParseVersion(previousVersionString)

    if not previousMajor then
        print(`"VERSION" at tag "{latestTag}" was not in the proper format. Skipping the comparison.`)
        print("Current version format is valid.")
        return
    end

    print(`Version at last release was "{previousMajor}.{previousMinor}.{previousPatch}".`)

    -- Check whether the versions are identical.
    if currentMajor == previousMajor and currentMinor == previousMinor and currentPatch == previousPatch then
        print("Version has not been updated since last release.")
        process.exit(1)
    end

    -- Validate a single semantic version increment with subordinate components reset.

    const isMajorBump = currentMajor == previousMajor + 1 and currentMinor == 0 and currentPatch == 0
    const isMinorBump = currentMajor == previousMajor and currentMinor == previousMinor + 1 and currentPatch == 0
    const isPatchBump = currentMajor == previousMajor
        and currentMinor == previousMinor
        and currentPatch == previousPatch + 1

    if isMajorBump then
        print("Valid major version bump.")
    elseif isMinorBump then
        print("Valid minor version bump.")
    elseif isPatchBump then
        print("Valid patch version bump.")
    else
        print("Invalid version bump, must follow semantic versioning.")
        print("Valid bumps are...")
        print(`  A major bump changes "{previousMajor}.{previousMinor}.{previousPatch}" to "{previousMajor + 1}.0.0".`)
        print(
            `  A minor bump changes "{previousMajor}.{previousMinor}.{previousPatch}" to "{previousMajor}.{previousMinor + 1}.0".`
        )
        print(
            `  A patch bump changes "{previousMajor}.{previousMinor}.{previousPatch}" to "{previousMajor}.{previousMinor}.{previousPatch + 1}".`
        )
        process.exit(1)
    end

    print("Version update is valid.")
end

EnsureProperVersionUpdate.exec()
