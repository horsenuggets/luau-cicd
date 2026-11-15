--[[

ExtractChangelog.func

Extracts the changelog section for a specific version from CHANGELOG.md. Optionally
accepts a path to the changelog file.

--]]

const fs = require("@lune/fs")

const function ExtractChangelog(version: string, changelogPath: string?): string?
    assert(type(version) == "string", "Expected a string for the version.")
    assert(
        changelogPath == nil or type(changelogPath) == "string",
        "Expected an optional string for the changelog path."
    )

    const filePath = changelogPath or "CHANGELOG.md"

    if not fs.isFile(filePath) then
        return nil
    end

    const content = fs.readFile(filePath)

    -- Find the start of the version section.
    const prefixedContent = `\n{content}`
    const startPos = string.find(prefixedContent, `\n## {version}\n`, 1, true)
        or string.find(prefixedContent, `\n## {version}\r\n`, 1, true)

    if not startPos then
        return nil
    end

    -- Find the end of the header line.
    const headerEnd = string.find(content, "\n", startPos)
    if not headerEnd then
        return nil
    end

    -- Find the next version header or the end of the file.
    const nextVersionPos = string.find(content, "\n## ", headerEnd)
    const endPos = nextVersionPos or #content + 1

    -- Extract the section content.
    local section = string.sub(content, headerEnd + 1, endPos - 1)

    -- Trim leading and trailing whitespace.
    section = string.match(section, "^%s*(.-)%s*$")

    if section == "" then
        return nil
    end

    return section
end

return ExtractChangelog
