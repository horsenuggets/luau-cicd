--[[

IsReleaseVersion.func

Checks whether a string is exactly a MAJOR.MINOR.PATCH release version, optionally with a
SemVer prerelease suffix like "-beta.6" or "-horse.0.5", and nothing else. Rejecting
everything else keeps tags, titles, and workflow outputs free of flags and newlines.

--]]

const ParseVersion = require("./ParseVersion.func")

-- Checks one dot-separated prerelease identifier. Numeric identifiers can't have leading
-- zeros, per SemVer.
const function isPrereleaseIdentifier(identifier: string): boolean
    if not string.match(identifier, "^[0-9A-Za-z%-]+$") then
        return false
    end
    return not string.match(identifier, "^0%d+$")
end

const function IsReleaseVersion(value: string): boolean
    assert(type(value) == "string", "Expected a string for the value.")

    const core, prerelease = string.match(value, "^(%d+%.%d+%.%d+)%-(.*)$")
    if not core then
        return string.match(value, "^%d+%.%d+%.%d+$") ~= nil and ParseVersion(value) ~= nil
    end

    if ParseVersion(core) == nil then
        return false
    end

    -- Appending a dot terminates every identifier, so empty ones show up as "".
    for identifier in string.gmatch(`{prerelease}.`, "([^.]*)%.") do
        if not isPrereleaseIdentifier(identifier) then
            return false
        end
    end
    return true
end

return IsReleaseVersion
