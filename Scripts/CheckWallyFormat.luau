#!/usr/bin/env -S lune run

--[[

CheckWallyFormat

Validates that wally.toml follows the project format guidelines. Specifically checks that
all repository strings (package name and dependency values) are lowercase.

Usage: lune run CheckWallyFormat [filename]
  filename: Optional path to the file to check. Defaults to "wally.toml".

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local function checkWallyFormat()
    local filename = process.args[1] or "wally.toml"

    print(`Checking {filename} format...`)

    -- Check file exists
    if not fs.isFile(filename) then
        print(`{filename} not found.`)
        process.exit(1)
    end

    local content = fs.readFile(filename)
    local errors: { string } = {}

    -- Track which section we're in
    local currentSection = ""

    for line in string.gmatch(content, "[^\n]+") do
        -- Check for section headers
        local section = string.match(line, "^%s*%[([%w%-_]+)%]")
        if section then
            currentSection = section
        end

        -- Check key = "value" pairs
        local key, value = string.match(line, '^%s*([%w%-_]+)%s*=%s*"(.-)"')
        if key and value then
            local shouldCheckLowercase = false
            local fieldDescription = ""

            -- Check package name (owner/repo format)
            if currentSection == "package" and key == "name" then
                shouldCheckLowercase = true
                fieldDescription = "Package name"
            end

            -- Check dependencies (owner/repo@version format)
            if currentSection == "dependencies" or currentSection == "dev-dependencies" then
                shouldCheckLowercase = true
                fieldDescription = `Dependency "{key}"`
            end

            if shouldCheckLowercase then
                local lowercase = string.lower(value)
                if value ~= lowercase then
                    table.insert(
                        errors,
                        `{fieldDescription} has non-lowercase value "{value}". Should be "{lowercase}".`
                    )
                end
            end
        end
    end

    -- Report results
    if #errors > 0 then
        print(`Found {#errors} format error(s) in {filename}:`)
        print("")
        for _, err in errors do
            print(`  - {err}`)
        end
        process.exit(1)
    end

    print(`{filename} format is valid.`)
end

checkWallyFormat()
