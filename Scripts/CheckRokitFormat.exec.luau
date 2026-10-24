#!/usr/bin/env -S lune run

--[[

CheckRokitFormat.exec

Validates that rokit.toml follows the project format guidelines. Specifically checks that
all tool repository strings are lowercase.

[Usage] ./Scripts/CheckRokitFormat.exec.luau [filename]
> filename - Optional path to the file to check. Defaults to "rokit.toml".

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")

const CheckRokitFormat = {}

function CheckRokitFormat.exec()
    const filename = process.args[1] or "rokit.toml"

    print(`Checking {filename} format...`)

    -- Check file exists
    if not fs.isFile(filename) then
        print(`{filename} not found.`)
        process.exit(1)
    end

    const content = fs.readFile(filename)
    const errors: { string } = {}

    -- Find all tool definitions: key = "value"
    -- Pattern matches lines like: luau-lsp = "johnnymorganz/luau-lsp@1.60.0"
    for line in string.gmatch(content, "[^\n]+") do
        const key, value = string.match(line, '^%s*([%w%-_]+)%s*=%s*"(.-)"')
        if key and value then
            -- Check if the value contains uppercase letters
            const lowercase = string.lower(value)
            if value ~= lowercase then
                table.insert(errors, `Tool "{key}" has non-lowercase value "{value}". Should be "{lowercase}".`)
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

CheckRokitFormat.exec()
