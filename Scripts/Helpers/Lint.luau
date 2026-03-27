--[[

Lint

Shared lint module that runs luau-lsp analyze with sensible defaults.
Downstream repos require this from the luau-cicd submodule instead of
maintaining their own lint logic.

By default, analyzes "." with --platform=lune, --no-flags-enabled, and
--enable-new-solver, ignoring DevPackages, Packages, Submodules, and
dotfolders. Accepts an optional config table to override platforms,
ignore patterns, and target directories.

--]]

local process = require("@lune/process")

local Lint = {}

local DEFAULT_IGNORE_PATTERNS = {
    "DevPackages/**",
    "Packages/**",
    "Submodules/**",
    ".*/**",
}

local function printOutput(result: process.ExecResult)
    if result.stdout ~= "" then
        print(result.stdout)
    end
    if result.stderr ~= "" then
        print(result.stderr)
    end
end

local function generateSourcemap(rojoProject: string, outputFile: string)
    local result = process.exec("rojo", {
        "sourcemap",
        rojoProject,
        "--output",
        outputFile,
    })

    if not result.ok then
        print(`Failed to generate sourcemap from "{rojoProject}".`)
        print(result.stderr)
        process.exit(1)
    end
end

local function buildIgnoreArgs(extraPatterns: { string }?): { string }
    local args = {}

    for _, pattern in DEFAULT_IGNORE_PATTERNS do
        table.insert(args, `--ignore={pattern}`)
    end

    if extraPatterns then
        for _, pattern in extraPatterns do
            table.insert(args, `--ignore={pattern}`)
        end
    end

    return args
end

local function analyze(
    label: string,
    platform: string,
    targets: { string },
    sourcemap: string?,
    ignoreArgs: { string }
): boolean
    print(`Analyzing {label}...`)

    local args = {
        "analyze",
        `--platform={platform}`,
        "--no-flags-enabled",
        "--enable-new-solver",
    }

    if sourcemap then
        table.insert(args, `--sourcemap={sourcemap}`)
    end

    for _, ignore in ignoreArgs do
        table.insert(args, ignore)
    end

    for _, target in targets do
        table.insert(args, target)
    end

    local result = process.exec("luau-lsp", args)
    printOutput(result)

    if result.ok then
        print(`No errors found in {label}.`)
    end

    return result.ok
end

export type Platform = {
    platform: string,
    targets: { string },
    sourcemap: string?,
    rojoProject: string?,
}

export type LintConfig = {
    platforms: { Platform }?,
    ignorePatterns: { string }?,
}

function Lint.run(config: LintConfig?)
    local cfg = config or {}
    local ignoreArgs = buildIgnoreArgs(cfg.ignorePatterns)

    local platforms: { Platform } = cfg.platforms or {
        { platform = "lune", targets = { "." } },
    }

    local allPassed = true

    for _, entry in platforms do
        local sourcemap = entry.sourcemap

        if not sourcemap and entry.rojoProject then
            sourcemap = "sourcemap.json"
            generateSourcemap(entry.rojoProject, sourcemap)
        end

        local label = table.concat(entry.targets, ", ")
        if not analyze(label, entry.platform, entry.targets, sourcemap, ignoreArgs) then
            allPassed = false
        end
    end

    if allPassed then
        print("All lint checks passed.")
    else
        process.exit(1)
    end
end

return Lint
