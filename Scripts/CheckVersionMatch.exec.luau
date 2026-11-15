#!/usr/bin/env -S lune run

--[[

CheckVersionMatch.exec

Ensures that the version in VERSION file matches the version in wally.toml and README.md
(if applicable). Exits with code 0 if they all match, 1 if they do not.

--]]

const GetReadmeVersionReferences = require("./Helpers/GetReadmeVersionReferences.func")
const fs = require("@lune/fs")
const process = require("@lune/process")
const serde = require("@lune/serde")

const CheckVersionMatch = {}

function CheckVersionMatch.exec()
    const versionFileContent = fs.readFile("VERSION")
    const version = string.match(versionFileContent, "^%s*(.-)%s*$")

    const wallyData = serde.decode("toml", fs.readFile("wally.toml"))
    const packageData = wallyData.package
    const wallyVersion = if type(packageData) == "table" then packageData.version else nil

    if type(wallyVersion) ~= "string" then
        print('Could not find the version in "wally.toml".')
        process.exit(1)
    end

    if version ~= wallyVersion then
        print(`Version mismatch. "VERSION" has "{version}", but "wally.toml" has "{wallyVersion}".`)
        process.exit(1)
    end

    -- Check README.md if it exists and has a Wally dependency string.
    const packageName = packageData.name
    assert(
        packageName == nil or type(packageName) == "string",
        'Expected the package name in "wally.toml" to be a string.'
    )

    if packageName and fs.isFile("README.md") then
        const readmeContent = fs.readFile("README.md")

        for _, reference in GetReadmeVersionReferences(readmeContent, packageName) do
            if reference.Version ~= version then
                print(
                    `Version mismatch. "VERSION" has "{version}", but "README.md" has "{packageName}@{reference.Version}".`
                )
                process.exit(1)
            end
        end
    end

    print(`All versions match "{version}".`)
    process.exit(0)
end

CheckVersionMatch.exec()
