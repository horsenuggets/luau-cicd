--[[

IsReleaseVersion.func

Checks whether a string is exactly a MAJOR.MINOR.PATCH release version with no
surrounding whitespace. Rejecting everything else keeps tags, titles, and workflow outputs
free of flags, newlines, and other injected text.

--]]

const ParseVersion = require("./ParseVersion.func")

const function IsReleaseVersion(value: string): boolean
    assert(type(value) == "string", "Expected a string for the value.")

    return string.match(value, "^%d+%.%d+%.%d+$") ~= nil and ParseVersion(value) ~= nil
end

return IsReleaseVersion
