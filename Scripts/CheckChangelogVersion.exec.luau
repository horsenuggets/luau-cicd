#!/usr/bin/env -S lune run

--[[

CheckChangelogVersion.exec

Validates that CHANGELOG.md contains an entry for the current VERSION.

--]]

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
    const pattern = `## {version:gsub("%.", "%%."):gsub("%-", "%%-")}`
    if not string.find(changelog, pattern) then
        print(`"CHANGELOG.md" does not contain an entry for version "{version}".`)
        print("Please add a changelog section before releasing.")
        process.exit(1)
    end

    -- Check that the version section has content.
    local sectionPattern = `## {version:gsub("%.", "%%."):gsub("%-", "%%-")}\n(.-)\n## `
    local section = string.match(changelog, sectionPattern)

    if not section then
        -- Try matching through the end of the file.
        sectionPattern = `## {version:gsub("%.", "%%."):gsub("%-", "%%-")}\n(.-)$`
        section = string.match(changelog, sectionPattern)
    end

    if not section or string.match(section, "^%s*$") then
        print(`"CHANGELOG.md" entry for version "{version}" is empty.`)
        print("Please add changelog content before releasing.")
        process.exit(1)
    end

    print(`"CHANGELOG.md" contains a valid entry for version "{version}".`)
end

CheckChangelogVersion.exec()
