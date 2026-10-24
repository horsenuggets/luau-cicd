#!/usr/bin/env -S lune run

--[[

CheckScriptExecutability.exec

Validates that all Luau scripts in the Scripts/ directory have the executable bit set and
start with the shebang line "#!/usr/bin/env -S lune run". Helper modules (non-root files
like Task/init.luau) are excluded from this check.

[Usage] ./Scripts/CheckScriptExecutability.exec.luau [directory]
> directory - Optional path to the Scripts directory to check. Defaults to
> "Scripts".

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")

const SHEBANG = "#!/usr/bin/env -S lune run"

const CheckScriptExecutability = {}

function CheckScriptExecutability.exec()
    const scriptsDir = process.args[1] or "Scripts"

    if not fs.isDir(scriptsDir) then
        print(`No "{scriptsDir}" directory found, skipping.`)
        process.exit(0)
    end

    const failures: { string } = {}

    for _, entry in fs.readDir(scriptsDir) do
        const path = `{scriptsDir}/{entry}`

        if not fs.isFile(path) or not entry:match("%.luau$") then
            continue
        end

        const contents = fs.readFile(path)
        const firstLine = contents:match("^([^\n]*)")

        if firstLine ~= SHEBANG then
            table.insert(failures, `{path} is missing shebang "{SHEBANG}"`)
        end

        const result = process.exec("test", { "-x", path })
        if not result.ok then
            table.insert(failures, `{path} is not executable (run: chmod +x {path})`)
        end
    end

    if #failures == 0 then
        print("All scripts have correct shebang and executable bit.")
        process.exit(0)
    end

    print(`Found {#failures} {if #failures == 1 then "issue" else "issues"}:\n`)
    for _, failure in failures do
        print(`  - {failure}`)
    end

    process.exit(1)
end

CheckScriptExecutability.exec()
