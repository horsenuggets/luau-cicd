--[[

extractChangelog

Extracts the changelog section for a specific version from CHANGELOG.md.

--]]

local fs = require("@lune/fs")

local function extractChangelog(version: string): string?
    assert(type(version) == "string", "version must be a string")

    if not fs.isFile("CHANGELOG.md") then
        return nil
    end

    local content = fs.readFile("CHANGELOG.md")

    -- Find the start of the version section
    local versionHeader = "## " .. version:gsub("%.", "%%.")
    local startPos = string.find(content, versionHeader)

    if not startPos then
        return nil
    end

    -- Find the end of the header line
    local headerEnd = string.find(content, "\n", startPos)
    if not headerEnd then
        return nil
    end

    -- Find the next version header or end of file
    local nextVersionPos = string.find(content, "\n## ", headerEnd)
    local endPos = nextVersionPos or #content + 1

    -- Extract the section content
    local section = string.sub(content, headerEnd + 1, endPos - 1)

    -- Trim leading and trailing whitespace
    section = string.match(section, "^%s*(.-)%s*$")

    if section == "" then
        return nil
    end

    return section
end

return extractChangelog
