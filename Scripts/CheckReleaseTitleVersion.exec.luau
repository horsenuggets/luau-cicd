#!/usr/bin/env -S lune run

--[[

CheckReleaseTitleVersion.exec

Requires a release PR title to match "Release <version>", where the version comes from the
"VERSION" file. Pass the title through an environment variable in workflows so that GitHub
expressions are never interpolated into the shell.

[Usage] ./Submodules/luau-cicd/Scripts/CheckReleaseTitleVersion.exec.luau "$TITLE"

--]]

const Fail = require("./Helpers/Fail.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const CheckReleaseTitleVersion = {}

function CheckReleaseTitleVersion.exec()
    if #process.args ~= 1 then
        Fail("[Usage] CheckReleaseTitleVersion.exec.luau <title>")
    end

    if not fs.isFile("VERSION") then
        Fail(`The "VERSION" file does not exist.`)
    end

    const title = process.args[1]
    const version = string.match(fs.readFile("VERSION"), "^%s*(.-)%s*$")
    const expectedTitle = `Release {version}`

    if title ~= expectedTitle then
        Fail(`PR title "{title}" does not match the "VERSION" file. Expected "{expectedTitle}".`)
    end

    print(`PR title matches the "VERSION" file.`)
end

CheckReleaseTitleVersion.exec()
