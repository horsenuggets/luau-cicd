#!/usr/bin/env -S lune run

--[[

CheckFormatting.exec

Verifies that all code is properly formatted using stylua.

--]]

const process = require("@lune/process")

const CheckFormatting = {}

function CheckFormatting.exec()
    const result = process.exec("stylua", { "--check", "." })

    if result.ok then
        print("Formatting check passed!")
        process.exit(0)
    else
        print("Formatting check failed.")
        print(result.stdout)
        print(result.stderr)
        process.exit(1)
    end
end

CheckFormatting.exec()
