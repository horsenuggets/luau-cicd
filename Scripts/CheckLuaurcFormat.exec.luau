#!/usr/bin/env -S lune run

--[[

CheckLuaurcFormat.exec

Validates that .luaurc follows the project format guidelines. Checks the following...
> "@self" is never added as an alias because it is already built in.
> The lune alias version matches the version in rokit.toml when lune is defined there.

[Usage] ./Scripts/CheckLuaurcFormat.exec.luau [luaurc-file] [rokit-file]
> luaurc-file → Optional path to the .luaurc file. Defaults to ".luaurc".
> rokit-file → Optional path to the rokit.toml file. Defaults to "rokit.toml".

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")
const serde = require("@lune/serde")

const function getLuneVersionFromRokit(rokitPath: string): string?
    assert(type(rokitPath) == "string", "Expected a string for the Rokit file path.")

    if not fs.isFile(rokitPath) then
        return nil
    end

    const ok, data = pcall(function()
        return serde.decode("toml", fs.readFile(rokitPath))
    end)
    assert(ok, `Failed to parse "{rokitPath}" as TOML. {data}`)
    if data.tools == nil then
        return nil
    end
    assert(type(data.tools) == "table", `Expected "tools" to be a table in "{rokitPath}".`)

    const lune = data.tools.lune
    if lune == nil then
        return nil
    end
    assert(type(lune) == "string", `Expected "tools.lune" to be a string in "{rokitPath}".`)
    const version = string.match(lune, "^[^@]+@(.+)$")
    assert(version ~= nil, `Expected "tools.lune" to include a version after "@" in "{rokitPath}".`)
    return version
end

const CheckLuaurcFormat = {}

function CheckLuaurcFormat.exec()
    const luaurcPath = process.args[1] or ".luaurc"
    const rokitPath = process.args[2] or "rokit.toml"

    print(`Checking "{luaurcPath}" format...`)

    -- Check that the file exists.
    if not fs.isFile(luaurcPath) then
        print(`"{luaurcPath}" was not found.`)
        process.exit(1)
    end

    const content = fs.readFile(luaurcPath)
    const errors: { string } = {}

    -- Parse the JSON content.
    const ok, data = pcall(function()
        return serde.decode("json", content)
    end)

    if not ok then
        print(`Failed to parse "{luaurcPath}" as JSON. {data}`)
        process.exit(1)
    end

    -- Check for an unsupported @self alias.
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

    -- Check that the lune alias version matches rokit.toml.
    const rokitLuneVersion = getLuneVersionFromRokit(rokitPath)
    if rokitLuneVersion then
        const luneAlias = data.aliases and data.aliases.lune
        if luneAlias then
            -- Require the version-specific typedef directory.
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
                `Lune is defined in "rokit.toml" with version "{rokitLuneVersion}", but "{luaurcPath}" has no lune alias. Set the "lune" alias to "~/.lune/.typedefs/{rokitLuneVersion}/".`
            )
        end
    end

    -- Report the validation results.
    if #errors > 0 then
        print(`Found {#errors} format {if #errors == 1 then "error" else "errors"} in "{luaurcPath}"...`)
        print("")
        for _, err in errors do
            print(`  - {err}`)
        end
        process.exit(1)
    end

    print(`"{luaurcPath}" format is valid.`)
end

CheckLuaurcFormat.exec()
