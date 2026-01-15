--[[

CheckChangelogFormat

Validates that CHANGELOG.md follows the exact format specified in the project guidelines.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local function checkChangelogFormat()
    print("Checking CHANGELOG.md format...")

    -- Check file exists
    if not fs.isFile("CHANGELOG.md") then
        print("CHANGELOG.md not found.")
        process.exit(1)
    end

    local content = fs.readFile("CHANGELOG.md")
    local errors: { string } = {}

    -- Check file ends with exactly one newline
    if not string.match(content, "\n$") then
        table.insert(errors, "File must end with a newline.")
    elseif string.match(content, "\n\n$") then
        table.insert(errors, "File must end with exactly one newline, not multiple.")
    end

    -- Split into lines for analysis
    local lines: { string } = {}
    for line in string.gmatch(content, "([^\n]*)\n?") do
        table.insert(lines, line)
    end

    -- Remove trailing empty string from split if present
    if lines[#lines] == "" then
        table.remove(lines)
    end

    -- Check first line is exactly "# Changelog"
    if #lines == 0 or lines[1] ~= "# Changelog" then
        table.insert(errors, `First line must be exactly "# Changelog", got "{lines[1] or ""}".`)
    end

    -- Check second line is empty (blank line after title)
    if #lines < 2 or lines[2] ~= "" then
        table.insert(errors, "Second line must be blank (after # Changelog header).")
    end

    -- Track state for validation
    local inVersionSection = false
    local lastLineType = "header" -- header, blank, version, item
    local hasVersions = false

    for i = 3, #lines do
        local line = lines[i]
        local prevLine = lines[i - 1]

        -- Check for version header (## X.Y.Z)
        local version = string.match(line, "^## (%d+%.%d+%.%d+)$")
        if version then
            hasVersions = true
            -- Version header must be preceded by a blank line (except at start)
            if prevLine ~= "" and lastLineType ~= "blank" then
                table.insert(errors, `Line {i}: Version header "## {version}" must be preceded by a blank line.`)
            end
            inVersionSection = true
            lastLineType = "version"

        -- Check for list item (- text)
        elseif string.match(line, "^%- ") then
            if not inVersionSection then
                table.insert(errors, `Line {i}: List item must be inside a version section.`)
            end

            -- Check item has content after "- "
            local itemContent = string.match(line, "^%- (.+)$")
            if not itemContent then
                table.insert(errors, `Line {i}: List item must have content after "- ".`)
            end

            lastLineType = "item"

        -- Check for blank line
        elseif line == "" then
            lastLineType = "blank"

        -- Any other line is invalid
        else
            -- Check for common mistakes
            if string.match(line, "^#[^#]") then
                table.insert(errors, `Line {i}: Invalid header format. Use "# Changelog" only at the top.`)
            elseif string.match(line, "^## ") then
                table.insert(errors, `Line {i}: Version header must be exactly "## X.Y.Z" format (e.g., "## 1.0.0").`)
            elseif string.match(line, "^### ") then
                table.insert(
                    errors,
                    `Line {i}: Subsection headers (###) are not allowed. List items go directly under version.`
                )
            elseif string.match(line, "^%-[^ ]") then
                table.insert(errors, `Line {i}: List items must have a space after the dash ("- item" not "-item").`)
            elseif string.match(line, "^%s+%-") then
                table.insert(errors, `Line {i}: List items must not be indented.`)
            else
                table.insert(errors, `Line {i}: Unexpected content "{line}".`)
            end
        end
    end

    if not hasVersions then
        table.insert(errors, "CHANGELOG.md must contain at least one version section (## X.Y.Z).")
    end

    -- Report results
    if #errors > 0 then
        print(`Found {#errors} format error(s) in CHANGELOG.md:`)
        print("")
        for _, err in errors do
            print(`  - {err}`)
        end
        process.exit(1)
    end

    print("CHANGELOG.md format is valid.")
end

checkChangelogFormat()
