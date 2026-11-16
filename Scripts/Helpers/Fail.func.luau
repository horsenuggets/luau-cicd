--[[

Fail.func

Reports a message as a GitHub Actions error annotation on stderr and exits with status 1.
Outside of GitHub Actions, the annotation prefix is harmless and the message still reads
as a complete sentence.

--]]

const process = require("@lune/process")
const stdio = require("@lune/stdio")

const function Fail(message: string): never
    assert(type(message) == "string", "Expected a string for the message.")

    stdio.ewrite(`::error::{message}\n`)
    return process.exit(1)
end

return Fail
