#!/usr/bin/env -S lune run

--[[

SyncVersion.exec

Synchronizes the version from the VERSION file to wally.toml and README.md (if a Wally
dependency string exists).

--]]

const GetReadmeVersionReferences = require("./Helpers/GetReadmeVersionReferences.func")
const ReplaceWallyPackageVersion = require("./Helpers/ReplaceWallyPackageVersion.func")
const fs = require("@lune/fs")
const serde = require("@lune/serde")

const SyncVersion = {}

function SyncVersion.exec()
    assert(fs.isFile("VERSION"), 'The "VERSION" file was not found.')
    assert(fs.isFile("wally.toml"), '"wally.toml" was not found.')

    -- Read the version from the VERSION file.
    local version = fs.readFile("VERSION")

    -- Trim whitespace from the version.
    version = string.match(version, "^%s*(.-)%s*$")
    assert(type(version) == "string" and version ~= "", 'The "VERSION" file is empty or invalid.')

    -- Read wally.toml.
    const wallyContent = fs.readFile("wally.toml")

    const wallyData = serde.decode("toml", wallyContent)
    const packageData = wallyData.package
    const packageName = if type(packageData) == "table" then packageData.name else nil
    assert(type(packageName) == "string", 'Could not find the package name in "wally.toml".')
    const currentVersion = packageData.version
    assert(type(currentVersion) == "string", 'Could not find the package version in "wally.toml".')
    const updatedWallyContent = ReplaceWallyPackageVersion(wallyContent, currentVersion, version)

    -- Write the updated content back to wally.toml.
    fs.writeFile("wally.toml", updatedWallyContent)
    print(`Updated "wally.toml" version to "{version}".`)

    -- Update README.md if it contains a Wally dependency string.
    if fs.isFile("README.md") then
        const readmeContent = fs.readFile("README.md")

        const references = GetReadmeVersionReferences(readmeContent, packageName)
        const count = #references

        if count > 0 then
            const parts = {}
            local nextIndex = 1
            for _, reference in references do
                table.insert(parts, string.sub(readmeContent, nextIndex, reference.Start - 1))
                table.insert(parts, version)
                nextIndex = reference.End + 1
            end
            table.insert(parts, string.sub(readmeContent, nextIndex))
            fs.writeFile("README.md", table.concat(parts))
            print(
                `Updated {count} version {if count == 1 then "reference" else "references"} in "README.md" to "{version}".`
            )
        else
            print('No version references were found in "README.md".')
        end
    end
end

SyncVersion.exec()
