--[[

ReplaceWallyPackageVersion.func

Replaces only the active package version string in a TOML manifest. Uses decoded TOML
to identify its source token while preserving comments and unrelated source bytes.

--]]

const serde = require("@lune/serde")

const function encodeString(value: string): string
    assert(type(value) == "string", "Expected a string value.")
    const encoded = serde.encode("toml", { Value = value })
    return string.match(encoded, "^Value%s*=%s*(.-)%s*$") :: string
end

const function ReplaceWallyPackageVersion(content: string, currentVersion: string, version: string): string
    assert(type(content) == "string", "Expected TOML content as a string.")
    assert(type(currentVersion) == "string", "Expected the current version as a string.")
    assert(type(version) == "string", "Expected the replacement version as a string.")

    const probe = `{currentVersion}__package_version_probe__`
    const probeLiteral = encodeString(probe)
    local index = 1
    while index <= #content do
        const character = string.sub(content, index, index)
        if character == "#" then
            index = string.find(content, "\n", index, true) or (#content + 1)
        elseif character == '"' or character == "'" then
            const startIndex = index
            const multiline = string.sub(content, index, index + 2) == string.rep(character, 3)
            index += if multiline then 3 else 1
            local endIndex: number? = nil
            while index <= #content do
                const nextCharacter = string.sub(content, index, index)
                if character == '"' and nextCharacter == "\\" then
                    index += 2
                elseif nextCharacter == character then
                    if multiline then
                        local quoteEnd = index
                        while string.sub(content, quoteEnd + 1, quoteEnd + 1) == character do
                            quoteEnd += 1
                        end
                        if quoteEnd - index + 1 >= 3 then
                            endIndex = quoteEnd
                            index = quoteEnd + 1
                            break
                        end
                        index = quoteEnd + 1
                    else
                        endIndex = index
                        index += 1
                        break
                    end
                else
                    index += 1
                end
            end
            assert(endIndex ~= nil, "Could not locate a complete TOML string.")
            const literal = string.sub(content, startIndex, endIndex)
            const valueOk, value = pcall(function()
                return serde.decode("toml", `Value = {literal}`).Value
            end)
            if valueOk and value == currentVersion then
                const prefix = string.sub(content, 1, startIndex - 1)
                const suffix = string.sub(content, endIndex + 1)
                const candidateOk, candidate = pcall(function()
                    return serde.decode("toml", `{prefix}{probeLiteral}{suffix}`)
                end)
                -- A token belongs to package.version only if changing it changes that field.
                if candidateOk and type(candidate.package) == "table" and candidate.package.version == probe then
                    const updated = `{prefix}{encodeString(version)}{suffix}`
                    assert(
                        serde.decode("toml", updated).package.version == version,
                        "Package version was not replaced."
                    )
                    return updated
                end
            end
        else
            index += 1
        end
    end
    error('Could not find the active package version in "wally.toml".')
end

return ReplaceWallyPackageVersion
