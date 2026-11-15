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

const CheckRokitFormat = {}

function CheckRokitFormat.exec()
    const filename = process.args[1] or "rokit.toml"

    print(`Checking "{filename}" format...`)

    -- Check that the file exists.
    if not fs.isFile(filename) then
        print(`"{filename}" was not found.`)
        process.exit(1)
    end

    const content = fs.readFile(filename)
    const errors: { string } = {}

    -- Find tool definitions with the key = "owner/repo@version" pattern.
    for line in string.gmatch(content, "[^\n]+") do
        const key, value = string.match(line, '^%s*([%w%-_]+)%s*=%s*"(.-)"')
        if key and value then
            -- Check whether the value contains uppercase letters.
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
