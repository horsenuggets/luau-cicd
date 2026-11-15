#!/usr/bin/env -S lune run

--[[

CheckVersionMatch.exec

Ensures that the version in VERSION file matches the version in wally.toml and README.md
(if applicable). Exits with code 0 if they all match, 1 if they do not.

--]]

const GetReadmeVersionReferences = require("./Helpers/GetReadmeVersionReferences.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const CheckVersionMatch = {}

function CheckVersionMatch.exec()
    const versionFileContent = fs.readFile("VERSION")
    const version = string.match(versionFileContent, "^%s*(.-)%s*$")

    const wallyContent = fs.readFile("wally.toml")
    const wallyVersion = string.match(wallyContent, '%[package%][^%[]*version%s*=%s*"(.-)"')

    if not wallyVersion then
        print('Could not find the version in "wally.toml".')
        process.exit(1)
    end

    if version ~= wallyVersion then
        print(`Version mismatch. "VERSION" has "{version}", but "wally.toml" has "{wallyVersion}".`)
        process.exit(1)
    end

    -- Check README.md if it exists and has a Wally dependency string.
    const packageName = string.match(wallyContent, '%[package%][^%[]*name%s*=%s*"(.-)"')

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
