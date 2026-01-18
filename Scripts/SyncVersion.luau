#!/usr/bin/env -S lune run

--[[

SyncVersion

Synchronizes the version from the VERSION file to wally.toml and README.md (if a Wally
dependency string exists).

--]]

local fs = require("@lune/fs")

local function syncVersion()
    -- Read version from VERSION file
    local version = fs.readFile("VERSION")

    -- Trim whitespace from version
    version = string.match(version, `^%s*(.-)%s*$`)

    -- Read wally.toml
    local wallyContent = fs.readFile("wally.toml")

    -- Extract the package name from wally.toml
    local packageName = string.match(wallyContent, `%[package%][^%[]*name%s*=%s*"(.-)"`)

    -- Find and replace version in [package] section only
    -- Pattern matches [package] section, then finds the first version = "..." line
    local updatedContent = string.gsub(wallyContent, `(%[package%][^%[]*version%s*=%s*)"(.-)"`, function(prefix, _)
        return `{prefix}"{version}"`
    end, 1)

    -- Write updated content back to wally.toml
    fs.writeFile("wally.toml", updatedContent)

    print(`Updated wally.toml version to "{version}".`)

    -- Update README.md if it exists and contains a Wally dependency string
    if packageName and fs.isFile("README.md") then
        local readmeContent = fs.readFile("README.md")

        -- Pattern to match packagename@version (e.g., horsenuggets/dotenv-luau@0.0.2)
        local escapedPackageName = string.gsub(packageName, "([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
        local pattern = `({escapedPackageName}@)[%d]+%.[%d]+%.[%d]+`

        local updatedReadme, count = string.gsub(readmeContent, pattern, `%1{version}`)

        if count > 0 then
            fs.writeFile("README.md", updatedReadme)
            print(`Updated {count} version reference(s) in README.md to "{version}".`)
        end
    end
end

syncVersion()
