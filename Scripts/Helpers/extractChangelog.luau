--[[

extractChangelog

Extracts the changelog section for a specific version from CHANGELOG.md. Optionally
accepts a path to the changelog file.

--]]

const fs = require("@lune/fs")

const function extractChangelog(version: string, changelogPath: string?): string?
    assert(type(version) == "string", "version must be a string")

    const filePath = changelogPath or "CHANGELOG.md"

    if not fs.isFile(filePath) then
        return nil
    end

    const content = fs.readFile(filePath)

    -- Find the start of the version section
    const versionHeader = "## " .. version:gsub("%.", "%%.")
    const startPos = string.find(content, versionHeader)

    if not startPos then
        return nil
    end

    -- Find the end of the header line
    const headerEnd = string.find(content, "\n", startPos)
    if not headerEnd then
        return nil
    end

    -- Find the next version header or end of file
    const nextVersionPos = string.find(content, "\n## ", headerEnd)
    const endPos = nextVersionPos or #content + 1

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
