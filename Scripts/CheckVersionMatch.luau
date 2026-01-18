#!/usr/bin/env -S lune run

--[[

CheckVersionMatch

Ensures that the version in VERSION file matches the version in wally.toml and README.md
(if applicable). Exits with code 0 if they all match, 1 if they do not.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local function checkVersionMatch()
    local versionFileContent = fs.readFile("VERSION")
    local version = string.match(versionFileContent, "^%s*(.-)%s*$")

    local wallyContent = fs.readFile("wally.toml")
    local wallyVersion = string.match(wallyContent, '%[package%][^%[]*version%s*=%s*"(.-)"')

    if not wallyVersion then
        print("Could not find version in wally.toml.")
        process.exit(1)
    end

    if version ~= wallyVersion then
        print(`Version mismatch. VERSION file has "{version}" but wally.toml has "{wallyVersion}".`)
        process.exit(1)
    end

    -- Check README.md if it exists and has a Wally dependency string
    local packageName = string.match(wallyContent, '%[package%][^%[]*name%s*=%s*"(.-)"')

    if packageName and fs.isFile("README.md") then
        local readmeContent = fs.readFile("README.md")

        -- Pattern to match packagename@version (e.g., horsenuggets/dotenv-luau@0.0.2)
        local escapedPackageName = string.gsub(packageName, "([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
        local pattern = `{escapedPackageName}@([%d]+%.[%d]+%.[%d]+)`

        local readmeVersion = string.match(readmeContent, pattern)

        if readmeVersion and readmeVersion ~= version then
            print(`Version mismatch. VERSION file has "{version}" but README.md has "{packageName}@{readmeVersion}".`)
            process.exit(1)
        end
    end

    print(`All versions match "{version}".`)
    process.exit(0)
end

checkVersionMatch()
