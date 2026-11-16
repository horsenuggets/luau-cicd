--[[

GetReleaseAssetSuffix.func

Normalizes a release platform like "linux-x86_64" to "linux-x64" for asset names. Accepts
"x86_64" and "x64" as x64 and "aarch64" and "arm64" as arm64. Returns nil and a complete
error sentence when the platform is not supported.

--]]

const ARCHITECTURES = {
    aarch64 = "arm64",
    arm64 = "arm64",
    x64 = "x64",
    x86_64 = "x64",
}
const OPERATING_SYSTEMS = {
    linux = true,
    macos = true,
    windows = true,
}

const function GetReleaseAssetSuffix(platform: string): (string?, string?)
    assert(type(platform) == "string", "Expected a string for the platform.")

    const os = string.match(platform, "^[^-]*") :: string
    const arch = string.sub(platform, #os + 2)
    if not OPERATING_SYSTEMS[os] then
        return nil, `Unsupported release operating system in "{platform}". Expected linux, macos, or windows.`
    end

    const canonicalArch = ARCHITECTURES[arch]
    if not canonicalArch then
        return nil, `Unsupported release architecture in "{platform}". Expected x86_64, x64, aarch64, or arm64.`
    end

    return `{os}-{canonicalArch}`, nil
end

return GetReleaseAssetSuffix
