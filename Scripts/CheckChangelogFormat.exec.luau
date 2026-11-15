#!/usr/bin/env -S lune run

--[[

CheckChangelogFormat.exec

Validates that CHANGELOG.md follows the exact format specified in the project guidelines.

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")

const CheckChangelogFormat = {}

function CheckChangelogFormat.exec()
    print('Checking "CHANGELOG.md" format...')

    -- Check that the file exists.
    if not fs.isFile("CHANGELOG.md") then
        print('"CHANGELOG.md" was not found.')
        process.exit(1)
    end

    const content = fs.readFile("CHANGELOG.md")
    const errors: { string } = {}

    -- Check that the file ends with exactly one newline.
    if not string.match(content, "\n$") then
        table.insert(errors, "File must end with a newline.")
    elseif string.match(content, "\n\n$") then
        table.insert(errors, "File must end with exactly one newline, not multiple.")
    end

    -- Split the content into lines for analysis.
    const lines: { string } = {}
    for line in string.gmatch(content, "([^\n]*)\n?") do
        table.insert(lines, line)
    end

    -- Remove the trailing empty string from the split if present.
    if lines[#lines] == "" then
        table.remove(lines)
    end

    -- Check that the first line is exactly "# Changelog".
    if #lines == 0 or lines[1] ~= "# Changelog" then
        table.insert(errors, `First line must be exactly "# Changelog", got "{lines[1] or ""}".`)
    end

    -- Check for a blank line after the title.
    if #lines < 2 or lines[2] ~= "" then
        table.insert(errors, 'Second line must be blank after the "# Changelog" header.')
    end

    -- Track the current section and previous line type for validation.
    local inVersionSection = false
    local lastLineType = "header"
    local hasVersions = false

    for i = 3, #lines do
        const line = lines[i]
        const prevLine = lines[i - 1]

        -- Check for a version header in the "## X.Y.Z" or "## X.Y.Z-suffix" format.
        const version = string.match(line, "^## (%d+%.%d+%.%d+[%w%.%-]*)$")
        if version then
            hasVersions = true
            -- Require a blank line before each version header.
            if prevLine ~= "" and lastLineType ~= "blank" then
                table.insert(errors, `Line {i} has a version header "## {version}" without a preceding blank line.`)
            end
            inVersionSection = true
            lastLineType = "version"

        -- Check for a list item beginning with "- ".
        elseif string.match(line, "^%- ") then
            if not inVersionSection then
                table.insert(errors, `Line {i} has a list item outside a version section.`)
            end

            -- Check that the item has content after "- ".
            const itemContent = string.match(line, "^%- (.+)$")
            if not itemContent then
                table.insert(errors, `Line {i} has a list item without content after "- ".`)
            end

            lastLineType = "item"

        -- Allow blank lines between items and sections.
        elseif line == "" then
            lastLineType = "blank"

        -- Report unsupported content and common formatting mistakes.
        else
            if string.match(line, "^#[^#]") then
                table.insert(errors, `Line {i} has an invalid header. Use "# Changelog" only at the top.`)
            elseif string.match(line, "^## ") then
                table.insert(
                    errors,
                    `Line {i} must use a version header in the "## X.Y.Z" or "## X.Y.Z-suffix" format.`
                )
            elseif string.match(line, "^### ") then
                table.insert(errors, `Line {i} has a subsection header. List items must go directly under the version.`)
            elseif string.match(line, "^%-[^ ]") then
                table.insert(errors, `Line {i} must use a space after the dash, such as "- item" rather than "-item".`)
            elseif string.match(line, "^%s+%-") then
                table.insert(errors, `Line {i} has an indented list item.`)
            else
                table.insert(errors, `Line {i} has unexpected content "{line}".`)
            end
        end
    end

    if not hasVersions then
        table.insert(errors, '"CHANGELOG.md" must contain at least one version section.')
    end

    -- Report the validation results.
    if #errors > 0 then
        print(`Found {#errors} format {if #errors == 1 then "error" else "errors"} in "CHANGELOG.md"...`)
        print("")
        for _, err in errors do
            print(`  - {err}`)
        end
        process.exit(1)
    end

    print('"CHANGELOG.md" format is valid.')
end

CheckChangelogFormat.exec()
