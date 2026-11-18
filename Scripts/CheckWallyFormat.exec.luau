#!/usr/bin/env -S lune run

--[[

CheckWallyFormat.exec

Validates that wally.toml follows the project format guidelines. Specifically checks that
registry package names and dependency references are lowercase, preserving local paths.

[Usage] ./Scripts/CheckWallyFormat.exec.luau [filename]
> filename → Optional path to the file to check. Defaults to "wally.toml".

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")
const serde = require("@lune/serde")

const CheckWallyFormat = {}

function CheckWallyFormat.exec()
    const filename = process.args[1] or "wally.toml"

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

    const function checkLowercase(value: unknown, fieldDescription: string)
        assert(type(fieldDescription) == "string", "Expected a field description string.")
        assert(type(value) == "string", `Expected {fieldDescription} to be a string in "{filename}".`)
        const lowercase = string.lower(value)
        if value ~= lowercase then
            table.insert(errors, `{fieldDescription} has non-lowercase value "{value}". Should be "{lowercase}".`)
        end
    end

    if data.package ~= nil then
        assert(type(data.package) == "table", `Expected "package" to be a table in "{filename}".`)
        if data.package.name ~= nil then
            checkLowercase(data.package.name, "Package name")
        end
    end

    for _, section in { "dependencies", "dev-dependencies", "server-dependencies" } do
        const dependencies = data[section]
        if dependencies ~= nil then
            assert(type(dependencies) == "table", `Expected "{section}" to be a table in "{filename}".`)
            const keys = {}
            for key in dependencies do
                assert(type(key) == "string", `Expected dependency names to be strings in "{filename}".`)
                table.insert(keys, key)
            end
            table.sort(keys)
            for _, key in keys do
                const value = dependencies[key]
                assert(type(value) == "string", `Expected Dependency "{key}" to be a string in "{filename}".`)
                if string.sub(value, 1, 1) ~= "^" then
                    checkLowercase(value, `Dependency "{key}"`)
                end
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

CheckWallyFormat.exec()
