#!/usr/bin/env -S lune run

--[[

CheckRokitFormat.exec

Validates that rokit.toml follows the project format guidelines. Specifically checks that
all tool repository strings are lowercase.

[Usage] ./Scripts/CheckRokitFormat.exec.luau [filename]
> filename → Optional path to the file to check. Defaults to "rokit.toml".

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")
const serde = require("@lune/serde")

const CheckRokitFormat = {}

function CheckRokitFormat.exec()
    const filename = process.args[1] or "rokit.toml"

    print(`Checking "{filename}" format...`)

    -- Check that the file exists.
    if not fs.isFile(filename) then
        print(`"{filename}" was not found.`)
        process.exit(1)
    end

    const ok, data = pcall(function()
        return serde.decode("toml", fs.readFile(filename))
    end)
    assert(ok, `Failed to parse "{filename}" as TOML. {data}`)
    const errors: { string } = {}

    if data.tools ~= nil then
        assert(type(data.tools) == "table", `Expected "tools" to be a table in "{filename}".`)
        const keys = {}
        for key in data.tools do
            assert(type(key) == "string", `Expected tool names to be strings in "{filename}".`)
            table.insert(keys, key)
        end
        table.sort(keys)
        for _, key in keys do
            const value = data.tools[key]
            assert(type(value) == "string", `Expected tool "{key}" to be a string in "{filename}".`)
            const lowercase = string.lower(value)
            if value ~= lowercase then
                table.insert(errors, `Tool "{key}" has non-lowercase value "{value}". Should be "{lowercase}".`)
            end
        end
    end

    -- Report the validation results.
    if #errors > 0 then
        print(`Found {#errors} format {if #errors == 1 then "error" else "errors"} in "{filename}"...`)
        print("")
        for _, err in errors do
            print(`  - {err}`)
        end
        process.exit(1)
    end

    print(`"{filename}" format is valid.`)
end

CheckRokitFormat.exec()
