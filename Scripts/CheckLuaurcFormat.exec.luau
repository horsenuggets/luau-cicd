#!/usr/bin/env -S lune run

--[[

CheckLuaurcFormat.exec

Validates that .luaurc follows the project format guidelines. Checks that:
- "@self" is never added as an alias since it is already built-in
- If lune is in rokit.toml, the lune alias version must match

[Usage] ./Scripts/CheckLuaurcFormat.exec.luau [luaurc-file] [rokit-file]
> luaurc-file - Optional path to the .luaurc file. Defaults to ".luaurc".
> rokit-file - Optional path to the rokit.toml file. Defaults to "rokit.toml".

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")
const serde = require("@lune/serde")

const function getLuneVersionFromRokit(rokitPath: string): string?
    if not fs.isFile(rokitPath) then
        return nil
    end

    const content = fs.readFile(rokitPath)

    -- Find lune = "owner/repo@version" pattern
    const version = string.match(content, 'lune%s*=%s*"[^@]+@([^"]+)"')
    return version
end

const CheckLuaurcFormat = {}

function CheckLuaurcFormat.exec()
    const luaurcPath = process.args[1] or ".luaurc"
    const rokitPath = process.args[2] or "rokit.toml"

    print(`Checking {luaurcPath} format...`)

    -- Check file exists
    if not fs.isFile(luaurcPath) then
        print(`{luaurcPath} not found.`)
        process.exit(1)
    end

    const content = fs.readFile(luaurcPath)
    const errors: { string } = {}

    -- Parse JSON
    const ok, data = pcall(function()
        return serde.decode("json", content)
    end)

    if not ok then
        print(`Failed to parse {luaurcPath} as JSON: {data}`)
        process.exit(1)
    end

    -- Check for @self alias
    if data.aliases then
        for key, _ in data.aliases do
            const lowerKey = string.lower(tostring(key))
            if lowerKey == "self" or lowerKey == "@self" then
                table.insert(
                    errors,
                    `Alias "{key}" is not allowed. @self is built-in and should never be added as an alias.`
                )
            end
        end
    end

    -- Check lune alias version matches rokit.toml
    const rokitLuneVersion = getLuneVersionFromRokit(rokitPath)
    if rokitLuneVersion then
        const luneAlias = data.aliases and data.aliases.lune
        if luneAlias then
            -- Expected format: ~/.lune/.typedefs/VERSION/
            const expectedPath = `~/.lune/.typedefs/{rokitLuneVersion}/`
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

CheckLuaurcFormat.exec()
