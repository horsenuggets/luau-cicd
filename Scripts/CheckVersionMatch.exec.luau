#!/usr/bin/env -S lune run

--[[

CheckVersionMatch.exec

Ensures that the version in VERSION file matches the version in wally.toml and README.md
(if applicable). Exits with code 0 if they all match, 1 if they do not.

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")

const CheckVersionMatch = {}

function CheckVersionMatch.exec()
    const versionFileContent = fs.readFile("VERSION")
    const version = string.match(versionFileContent, "^%s*(.-)%s*$")

    const wallyContent = fs.readFile("wally.toml")
    const wallyVersion = string.match(wallyContent, '%[package%][^%[]*version%s*=%s*"(.-)"')

    if not wallyVersion then
        print("Could not find version in wally.toml.")
        process.exit(1)
    end

    if version ~= wallyVersion then
        print(`Version mismatch. VERSION file has "{version}" but wally.toml has "{wallyVersion}".`)
        process.exit(1)
    end

    -- Check README.md if it exists and has a Wally dependency string
    const packageName = string.match(wallyContent, '%[package%][^%[]*name%s*=%s*"(.-)"')

    if packageName and fs.isFile("README.md") then
        const readmeContent = fs.readFile("README.md")

        -- Pattern to match packagename@version (e.g., horsenuggets/dotenv-luau@0.0.2
        -- or horsenuggets/t@3.1.1-horse.0.3)
        const escapedPackageName = string.gsub(packageName, "([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
        const pattern = `{escapedPackageName}@([%d][%w%.%-]*)`

        const readmeVersion = string.match(readmeContent, pattern)

        if readmeVersion and readmeVersion ~= version then
            print(`Version mismatch. VERSION file has "{version}" but README.md has "{packageName}@{readmeVersion}".`)
            process.exit(1)
        end
    end

    print(`All versions match "{version}".`)
    process.exit(0)
end

CheckVersionMatch.exec()
