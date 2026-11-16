#!/usr/bin/env -S lune run

--[[

PublishToWally.exec

Writes "WALLY_AUTH" to "~/.wally/auth.toml" and runs "wally publish". Skips publishing
when there is no "wally.toml" or the package is private, matching the rules CheckWallyAuth
uses, so a release never fails here after its tag is pushed.

[Usage] WALLY_AUTH="..." ./Submodules/luau-cicd/Scripts/PublishToWally.exec.luau

--]]

const Fail = require("./Helpers/Fail.func")
const GetWallyPublishSkipReason = require("./Helpers/GetWallyPublishSkipReason.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const PublishToWally = {}

function PublishToWally.exec()
    if #process.args ~= 0 then
        Fail("[Usage] PublishToWally.exec.luau")
    end

    const skipReason = GetWallyPublishSkipReason()
    if skipReason then
        print(`{skipReason} Skipping publishing to Wally.`)
        return
    end

    const auth = process.env.WALLY_AUTH
    if auth == nil or string.match(auth, "^%s*$") then
        Fail(`The "WALLY_AUTH" secret is not configured.`)
    end

    const home = process.env.HOME
    if home == nil or home == "" then
        Fail(`The "HOME" environment variable must be set.`)
    end

    const authDir = `{home}/.wally`
    if not fs.isDir(authDir) then
        fs.writeDir(authDir)
    end
    fs.writeFile(`{authDir}/auth.toml`, auth)

    if not process.exec("wally", { "publish" }, { stdio = "inherit" }).ok then
        Fail("Could not publish to Wally.")
    end

    print("Published to Wally.")
end

PublishToWally.exec()
