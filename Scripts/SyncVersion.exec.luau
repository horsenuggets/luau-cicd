#!/usr/bin/env -S lune run

--[[

SyncVersion.exec

Synchronizes the version from the VERSION file to wally.toml and README.md (if a Wally
dependency string exists).

--]]

const fs = require("@lune/fs")

const SyncVersion = {}

function SyncVersion.exec()
    assert(fs.isFile("VERSION"), 'The "VERSION" file was not found.')
    assert(fs.isFile("wally.toml"), '"wally.toml" was not found.')

    -- Read the version from the VERSION file.
    local version = fs.readFile("VERSION")

    -- Trim whitespace from the version.
    version = string.match(version, "^%s*(.-)%s*$")
    assert(type(version) == "string", 'The "VERSION" file is empty or invalid.')

    -- Read wally.toml.
    const wallyContent = fs.readFile("wally.toml")

    -- Extract the package name from wally.toml.
    const packageName = string.match(wallyContent, `%[package%][^%[]*name%s*=%s*"(.-)"`)
    assert(type(packageName) == "string", 'Could not find the package name in "wally.toml".')

    -- Replace the first version value in the [package] section only.
    const updatedWallyContent = string.gsub(wallyContent, '(%[package%][^%[]*version%s*=%s*)"(.-)"', function(prefix, _)
        return `{prefix}"{version}"`
    end, 1)

    -- Write the updated content back to wally.toml.
    fs.writeFile("wally.toml", updatedWallyContent)
    print(`Updated "wally.toml" version to "{version}".`)

    -- Update README.md if it contains a Wally dependency string.
    if fs.isFile("README.md") then
        const readmeContent = fs.readFile("README.md")

        -- Match a dependency coordinate such as owner/package@1.2.3.
        const escapedPackageName = string.gsub(packageName, "([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
        const pattern = `({escapedPackageName}@)[%d][%w%.%-]*`

        const updatedReadme, count = string.gsub(readmeContent, pattern, `%1{version}`)

        if count > 0 then
            fs.writeFile("README.md", updatedReadme)
            print(
                `Updated {count} version {if count == 1 then "reference" else "references"} in "README.md" to "{version}".`
            )
        else
            print('No version references were found in "README.md".')
        end
    end
end

SyncVersion.exec()
