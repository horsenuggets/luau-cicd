#!/usr/bin/env -S lune run

--[[

CheckFormatting.exec

Verifies formatting using an explicit binary or auto-detected StyLuau/StyLua.

[Usage] ./Scripts/CheckFormatting.exec.luau [binary]

--]]

const Fail = require("./Helpers/Fail.func")
const ResolveFormatterBinary = require("./Helpers/ResolveFormatterBinary.func")
const process = require("@lune/process")

const CheckFormatting = {}

const function isAvailable(binary: string): boolean
    assert(type(binary) == "string", "Expected a binary string.")

    const ok, result = pcall(process.exec, binary, { "--version" })
    return ok and result.ok
end

function CheckFormatting.exec()
    if #process.args > 1 or process.args[1] == "" then
        Fail("[Usage] CheckFormatting.exec.luau [binary]")
    end

    const binary = ResolveFormatterBinary(process.args[1], isAvailable)
    if binary == nil then
        Fail('Neither "styluau" nor "stylua" is usable. Install a formatter or pass its binary name.')
    end

    print(`Checking formatting with "{binary}".`)
    const ok, result = pcall(process.exec, binary, { "--check", "." })
    if not ok then
        Fail(`Could not run formatter "{binary}". {result}`)
    end

    if result.ok then
        print("Formatting check passed.")
        process.exit(0)
    else
        print("Formatting check failed.")
        print(result.stdout)
        print(result.stderr)
        process.exit(1)
    end
end

CheckFormatting.exec()
