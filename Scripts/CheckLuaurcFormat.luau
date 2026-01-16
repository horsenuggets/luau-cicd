#!/usr/bin/env -S lune run

--[[

CheckLuaurcFormat

Validates that .luaurc follows the project format guidelines. Checks that:
- "@self" is never added as an alias since it is already built-in
- If lune is in rokit.toml, the lune alias version must match

Usage: lune run CheckLuaurcFormat [luaurc-file] [rokit-file]
  luaurc-file: Optional path to the .luaurc file. Defaults to ".luaurc".
  rokit-file: Optional path to the rokit.toml file. Defaults to "rokit.toml".

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local function getLuneVersionFromRokit(rokitPath: string): string?
    if not fs.isFile(rokitPath) then
        return nil
    end

    local content = fs.readFile(rokitPath)

    -- Find lune = "owner/repo@version" pattern
    local version = string.match(content, 'lune%s*=%s*"[^@]+@([^"]+)"')
    return version
end

local function checkLuaurcFormat()
    local luaurcPath = process.args[1] or ".luaurc"
    local rokitPath = process.args[2] or "rokit.toml"

    print(`Checking {luaurcPath} format...`)

    -- Check file exists
    if not fs.isFile(luaurcPath) then
        print(`{luaurcPath} not found.`)
        process.exit(1)
    end

    local content = fs.readFile(luaurcPath)
    local errors: { string } = {}

    -- Parse JSON
    local ok, data = pcall(function()
        return serde.decode("json", content)
    end)

    if not ok then
        print(`Failed to parse {luaurcPath} as JSON: {data}`)
        process.exit(1)
    end

    -- Check for @self alias
    if data.aliases then
        for key, _ in data.aliases do
            local lowerKey = string.lower(key)
            if lowerKey == "self" or lowerKey == "@self" then
                table.insert(
                    errors,
                    `Alias "{key}" is not allowed. @self is built-in and should never be added as an alias.`
                )
            end
        end
    end

    -- Check lune alias version matches rokit.toml
    local rokitLuneVersion = getLuneVersionFromRokit(rokitPath)
    if rokitLuneVersion then
        local luneAlias = data.aliases and data.aliases.lune
        if luneAlias then
            -- Expected format: ~/.lune/.typedefs/VERSION/
            local expectedPath = `~/.lune/.typedefs/{rokitLuneVersion}/`
            if luneAlias ~= expectedPath then
                table.insert(
                    errors,
                    `Lune alias path "{luneAlias}" does not match rokit.toml version. Expected "{expectedPath}".`
                )
            end
        else
            table.insert(
                errors,
                `Lune is defined in rokit.toml (version {rokitLuneVersion}) but no lune alias found in {luaurcPath}. Expected alias: "lune": "~/.lune/.typedefs/{rokitLuneVersion}/".`
            )
        end
    end

    -- Report results
    if #errors > 0 then
        print(`Found {#errors} format error(s) in {luaurcPath}:`)
        print("")
        for _, err in errors do
            print(`  - {err}`)
        end
        process.exit(1)
    end

    print(`{luaurcPath} format is valid.`)
end

checkLuaurcFormat()
