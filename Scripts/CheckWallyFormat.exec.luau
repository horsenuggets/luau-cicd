#!/usr/bin/env -S lune run

--[[

CheckWallyFormat.exec

Validates that wally.toml follows the project format guidelines. Specifically checks that
all repository strings (package name and dependency values) are lowercase.

[Usage] ./Scripts/CheckWallyFormat.exec.luau [filename]
> filename → Optional path to the file to check. Defaults to "wally.toml".

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")

const CheckWallyFormat = {}

function CheckWallyFormat.exec()
    const filename = process.args[1] or "wally.toml"

    print(`Checking "{filename}" format...`)

    -- Check that the file exists.
    if not fs.isFile(filename) then
        print(`"{filename}" was not found.`)
        process.exit(1)
    end

    const content = fs.readFile(filename)
    const errors: { string } = {}

    -- Track the current section.
    local currentSection = ""

    for line in string.gmatch(content, "[^\n]+") do
        -- Check for section headers.
        const section = string.match(line, "^%s*%[([%w%-_]+)%]")
        if section then
            currentSection = section
        end

        -- Check key = "value" pairs.
        const key, value = string.match(line, '^%s*([%w%-_]+)%s*=%s*"(.-)"')
        if key and value then
            local shouldCheckLowercase = false
            local fieldDescription = ""

            -- Check the package name in owner/repo format.
            if currentSection == "package" and key == "name" then
                shouldCheckLowercase = true
                fieldDescription = "Package name"
            end

            -- Check dependencies in owner/repo@version format.
            if
                currentSection == "dependencies"
                or currentSection == "dev-dependencies"
                or currentSection == "server-dependencies"
            then
                shouldCheckLowercase = true
                fieldDescription = `Dependency "{key}"`
            end

            if shouldCheckLowercase then
                const lowercase = string.lower(value)
                if value ~= lowercase then
                    table.insert(
                        errors,
                        `{fieldDescription} has non-lowercase value "{value}". Should be "{lowercase}".`
                    )
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
