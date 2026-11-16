#!/usr/bin/env -S lune run

--[[

EnsureProperVersionUpdate.exec

Validates that the VERSION file contains a proper release version and that it has been
bumped correctly since the last release tag. Plain versions must take exactly one major,
minor, or patch step, while versions with a prerelease suffix only need to increase.

--]]

const CompareReleaseVersions = require("./Helpers/CompareReleaseVersions.func")
const IsReleaseVersion = require("./Helpers/IsReleaseVersion.func")
const ParseVersion = require("./Helpers/ParseVersion.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const EnsureProperVersionUpdate = {}

const function trim(value: string): string
    return string.match(value, "^%s*(.-)%s*$") or ""
end

-- Finds the highest release version tag by SemVer precedence, ignoring 0.0.0.
const function findLatestReleaseTag(): string?
    const tagResult = process.exec("git", { "tag", "--list" })
    if not tagResult.ok then
        return nil
    end

    local latestTag: string? = nil
    for tag in string.gmatch(tagResult.stdout, "[^\n]+") do
        if tag ~= "0.0.0" and IsReleaseVersion(tag) then
            if latestTag == nil or CompareReleaseVersions(tag, latestTag) > 0 then
                latestTag = tag
            end
        end
    end
    return latestTag
end

-- Requires exactly one major, minor, or patch step between two plain versions.
const function checkPlainBump(current: string, previous: string)
    const currentMajor, currentMinor, currentPatch = ParseVersion(current)
    const previousMajor, previousMinor, previousPatch = ParseVersion(previous)
    assert(currentMajor and currentMinor and currentPatch, "Expected a plain current version.")
    assert(previousMajor and previousMinor and previousPatch, "Expected a plain previous version.")

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
        print(`  A major bump changes "{previous}" to "{previousMajor + 1}.0.0".`)
        print(`  A minor bump changes "{previous}" to "{previousMajor}.{previousMinor + 1}.0".`)
        print(`  A patch bump changes "{previous}" to "{previousMajor}.{previousMinor}.{previousPatch + 1}".`)
        process.exit(1)
    end
end

function EnsureProperVersionUpdate.exec()
    assert(fs.isFile("VERSION"), 'The "VERSION" file does not exist.')

    const current = trim(fs.readFile("VERSION"))
    if not IsReleaseVersion(current) then
        print(
            `The "VERSION" file is not in MAJOR.MINOR.PATCH format, with an optional prerelease suffix. Its current content is "{current}".`
        )
        process.exit(1)
    end

    print(`Current version is "{current}".`)

    const latestTag = findLatestReleaseTag()
    if not latestTag then
        print("No previous release tags found.")
        print("Version format is valid.")
        return
    end

    print(`Latest release tag is "{latestTag}".`)

    const versionAtTagResult = process.exec("git", { "show", `{latestTag}:VERSION` })
    if not versionAtTagResult.ok then
        print(`Could not read "VERSION" at tag "{latestTag}".`)
        print("Version format is valid.")
        return
    end

    const previous = trim(versionAtTagResult.stdout)
    if not IsReleaseVersion(previous) then
        print(`"VERSION" at tag "{latestTag}" was not in the proper format. Skipping the comparison.`)
        print("Current version format is valid.")
        return
    end

    print(`Version at last release was "{previous}".`)

    const comparison = CompareReleaseVersions(current, previous)
    if comparison == 0 then
        print("Version has not been updated since last release.")
        process.exit(1)
    end

    -- Suffix schemes differ (betas, fork counters), so only require that they move forward.
    if string.find(current, "-", 1, true) or string.find(previous, "-", 1, true) then
        if comparison < 0 then
            print(`Invalid version update. "{current}" must be newer than "{previous}".`)
            process.exit(1)
        end
        print("Valid prerelease version update.")
    else
        checkPlainBump(current, previous)
    end

    print("Version update is valid.")
end

EnsureProperVersionUpdate.exec()
