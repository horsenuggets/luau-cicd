--[[

WriteGitHubOutputs.func

Appends key and value pairs to the file named by "GITHUB_OUTPUT" in sorted key order.
Rejects values containing newlines, since a newline would let a value inject extra
outputs into later workflow steps.

--]]

const fs = require("@lune/fs")

const function WriteGitHubOutputs(outputPath: string, outputs: { [string]: string })
    assert(type(outputPath) == "string", "Expected a string for the output path.")
    assert(type(outputs) == "table", "Expected a table of outputs.")

    const keys = {}
    for key, value in outputs do
        assert(string.match(key, "^[%w_]+$"), `Expected the output name "{key}" to be a word.`)
        assert(not string.find(value, "[\r\n]"), `Expected the output "{key}" to be a single line.`)
        table.insert(keys, key)
    end
    table.sort(keys)

    const lines = {}
    for _, key in keys do
        table.insert(lines, `{key}={outputs[key]}\n`)
    end

    const existing = if fs.isFile(outputPath) then fs.readFile(outputPath) else ""
    fs.writeFile(outputPath, `{existing}{table.concat(lines)}`)
end

return WriteGitHubOutputs
