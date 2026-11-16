#!/usr/bin/env -S lune run

--[[

GetReleaseAssetSuffix.exec

Prints the canonical release asset suffix for a platform, like "linux-x64" for
"linux-x86_64". Writes nothing to stdout on failure, so shell substitutions never capture
a partial result.

[Usage] ./Submodules/luau-cicd/Scripts/GetReleaseAssetSuffix.exec.luau <os>-<arch>

--]]

const Fail = require("./Helpers/Fail.func")
const GetReleaseAssetSuffixFunc = require("./Helpers/GetReleaseAssetSuffix.func")
const process = require("@lune/process")
const stdio = require("@lune/stdio")

const GetReleaseAssetSuffix = {}

function GetReleaseAssetSuffix.exec()
    if #process.args ~= 1 then
        Fail("[Usage] GetReleaseAssetSuffix.exec.luau <linux|macos|windows>-<x86_64|x64|aarch64|arm64>")
    end

    const suffix, suffixError = GetReleaseAssetSuffixFunc(process.args[1])
    if not suffix then
        Fail(suffixError :: string)
    end

    stdio.write(`{suffix}\n`)
end

GetReleaseAssetSuffix.exec()
