#!/usr/bin/env -S lune run

--[[

RunStaticAnalysis.exec

Runs luau-lsp static analysis. Accepts an optional platform argument
(defaults to "standard"). The horsenuggets/luau-lsp fork handles
shebangs natively, so no stripping is needed.

[Usage] ./Scripts/RunStaticAnalysis.exec.luau [platform]

--]]

const process = require("@lune/process")

const RunStaticAnalysis = {}

function RunStaticAnalysis.exec()
    const platform = process.args[1] or "standard"

    print(`Running static analysis with platform "{platform}"...`)

    const result = process.exec("luau-lsp", {
        "analyze",
        "--platform",
        platform,
        "--ignore",
        "DevPackages/**",
        "--ignore",
        "Packages/**",
        "--ignore",
        "Submodules/**",
        ".",
    })

    -- Check for any issues in output (warnings or errors)
    -- luau-lsp outputs issues in the format: file(line,col): Type: message
    local hasIssues = false
    const issuePattern = "%):%s+%w+:"

    if string.find(result.stdout, issuePattern) then
        hasIssues = true
    end

    if not result.ok then
        print("Static analysis failed.")
        print(result.stdout)
        print(result.stderr)
        process.exit(1)
    elseif hasIssues then
        print("Static analysis found warnings:")
        print(result.stdout)
        process.exit(1)
    else
        print("Static analysis passed!")
        process.exit(0)
    end
end

RunStaticAnalysis.exec()
