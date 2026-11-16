--[[

CompareReleaseVersions.func

Compares two release versions by SemVer precedence and returns -1, 0, or 1. Both inputs
must pass IsReleaseVersion. A version with a prerelease suffix sorts before the same
version without one, and suffix identifiers compare numerically or lexically per SemVer.

--]]

const IsReleaseVersion = require("./IsReleaseVersion.func")

const function compareNumbers(a: number, b: number): number
    return if a < b then -1 elseif a > b then 1 else 0
end

const function splitVersion(version: string): ({ number }, { string }?)
    const major, minor, patch, prerelease = string.match(version, "^(%d+)%.(%d+)%.(%d+)%-?(.*)$")
    const core = { tonumber(major) :: number, tonumber(minor) :: number, tonumber(patch) :: number }
    if prerelease == "" then
        return core, nil
    end

    const identifiers = {}
    for identifier in string.gmatch(prerelease :: string, "[^.]+") do
        table.insert(identifiers, identifier)
    end
    return core, identifiers
end

const function compareIdentifiers(a: string, b: string): number
    const aNumber = if string.match(a, "^%d+$") then tonumber(a) else nil
    const bNumber = if string.match(b, "^%d+$") then tonumber(b) else nil

    -- Numeric identifiers always have lower precedence than alphanumeric ones.
    if aNumber and bNumber then
        return compareNumbers(aNumber, bNumber)
    elseif aNumber then
        return -1
    elseif bNumber then
        return 1
    end
    return if a < b then -1 elseif a > b then 1 else 0
end

const function CompareReleaseVersions(a: string, b: string): number
    assert(type(a) == "string" and IsReleaseVersion(a), "Expected a release version for the first argument.")
    assert(type(b) == "string" and IsReleaseVersion(b), "Expected a release version for the second argument.")

    const aCore, aPrerelease = splitVersion(a)
    const bCore, bPrerelease = splitVersion(b)

    for i = 1, 3 do
        const result = compareNumbers(aCore[i], bCore[i])
        if result ~= 0 then
            return result
        end
    end

    if not aPrerelease or not bPrerelease then
        if not aPrerelease and not bPrerelease then
            return 0
        end
        return if aPrerelease then -1 else 1
    end

    for i = 1, math.max(#aPrerelease, #bPrerelease) do
        const aIdentifier, bIdentifier = aPrerelease[i], bPrerelease[i]
        if aIdentifier == nil then
            return -1
        elseif bIdentifier == nil then
            return 1
        end

        const result = compareIdentifiers(aIdentifier, bIdentifier)
        if result ~= 0 then
            return result
        end
    end
    return 0
end

return CompareReleaseVersions
