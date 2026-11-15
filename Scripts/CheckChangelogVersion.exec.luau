#!/usr/bin/env -S lune run

--[[

CheckChangelogVersion.exec

Validates that CHANGELOG.md contains an entry for the current VERSION.

--]]

const ExtractChangelog = require("./Helpers/ExtractChangelog.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const CheckChangelogVersion = {}

function CheckChangelogVersion.exec()
    -- Read the current version.
    if not fs.isFile("VERSION") then
        print('The "VERSION" file was not found.')
        process.exit(1)
    end

    local version = fs.readFile("VERSION")
    version = string.match(version, "^%s*(.-)%s*$")

    print(`Checking for version "{version}" in "CHANGELOG.md"...`)

    -- Read the changelog.
    if not fs.isFile("CHANGELOG.md") then
        print('"CHANGELOG.md" was not found.')
        process.exit(1)
    end

    const changelog = fs.readFile("CHANGELOG.md")

    -- Check whether the version header exists.
    const normalizedChangelog = string.gsub(changelog, "\r\n", "\n")
    if not string.find(`\n{normalizedChangelog}\n`, `\n## {version}\n`, 1, true) then
        print(`"CHANGELOG.md" does not contain an entry for version "{version}".`)
        print("Please add a changelog section before releasing.")
        process.exit(1)
    end

    -- Check that the version section has content.
    const section = ExtractChangelog(version)

    if not section then
        print(`"CHANGELOG.md" entry for version "{version}" is empty.`)
        print("Please add changelog content before releasing.")
        process.exit(1)
    end

    print(`"CHANGELOG.md" contains a valid entry for version "{version}".`)
end

CheckChangelogVersion.exec()
