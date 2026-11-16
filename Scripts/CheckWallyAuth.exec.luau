#!/usr/bin/env -S lune run

--[[

CheckWallyAuth.exec

Requires the "WALLY_AUTH" environment variable before a release that publishes to Wally.
Skips the check when there is no "wally.toml" or the package is private, matching the
rules PublishToWally uses. Reads the secret from the environment so it never appears in
arguments.

[Usage] WALLY_AUTH="..." ./Submodules/luau-cicd/Scripts/CheckWallyAuth.exec.luau

--]]

const Fail = require("./Helpers/Fail.func")
const GetWallyPublishSkipReason = require("./Helpers/GetWallyPublishSkipReason.func")
const process = require("@lune/process")

const CheckWallyAuth = {}

function CheckWallyAuth.exec()
    if #process.args ~= 0 then
        Fail("[Usage] CheckWallyAuth.exec.luau")
    end

    const skipReason = GetWallyPublishSkipReason()
    if skipReason then
        print(`{skipReason} Skipping the "WALLY_AUTH" check.`)
        return
    end

    const auth = process.env.WALLY_AUTH
    if auth == nil or string.match(auth, "^%s*$") then
        Fail(`The "WALLY_AUTH" secret is not configured. Add it with "gh secret set WALLY_AUTH < ~/.wally/auth.toml".`)
    end

    print(`The "WALLY_AUTH" secret is configured.`)
end

CheckWallyAuth.exec()
