#!/usr/bin/env -S lune run

--[[

SyncVersion.exec

Synchronizes the version from the VERSION file to wally.toml and README.md (if a Wally
dependency string exists).

--]]

const fs = require("@lune/fs")

const SyncVersion = {}

function SyncVersion.exec()
    assert(fs.isFile("VERSION"), "VERSION file not found")
    assert(fs.isFile("wally.toml"), "wally.toml not found")

    -- Read version from VERSION file
    local version = fs.readFile("VERSION")

    -- Trim whitespace from version
    version = string.match(version, "^%s*(.-)%s*$")
    assert(type(version) == "string", "VERSION file is empty or invalid")

    -- Read wally.toml
    const wallyContent = fs.readFile("wally.toml")

    -- Extract the package name from wally.toml
    const packageName = string.match(wallyContent, `%[package%][^%[]*name%s*=%s*"(.-)"`)
    assert(type(packageName) == "string", "Could not find package name in wally.toml")

    -- Find and replace version in [package] section only
    -- Pattern matches [package] section, then finds the first version = "..." line
    const updatedWallyContent = string.gsub(wallyContent, '(%[package%][^%[]*version%s*=%s*)"(.-)"', function(prefix, _)
        return `{prefix}"{version}"`
    end, 1)

    -- Write updated content back to wally.toml
    fs.writeFile("wally.toml", updatedWallyContent)
    print(`Updated wally.toml version to "{version}".`)

    -- Update README.md if it exists and contains a Wally dependency string
    if fs.isFile("README.md") then
        const readmeContent = fs.readFile("README.md")

        -- Pattern to match packagename@version (e.g., horsenuggets/dotenv-luau@0.0.2
        -- or horsenuggets/t@3.1.1-horse.0.3)
        const escapedPackageName = string.gsub(packageName, "([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
        const pattern = `({escapedPackageName}@)[%d][%w%.%-]*`

        const updatedReadme, count = string.gsub(readmeContent, pattern, `%1{version}`)

        if count > 0 then
            fs.writeFile("README.md", updatedReadme)
            print(`Updated {count} version reference(s) in README.md to "{version}".`)
        else
            print("No version references found in README.md.")
        end
    end
end

SyncVersion.exec()
