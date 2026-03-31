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
    "ServerPackages/**",
    "Submodules/**",
    ".*/**",
}

local function getProjectName(): string
    local cwd = process.cwd
    local name = string.match(cwd, "([^/]+)/?$")
    return name or "."
end

local function formatTarget(target: string): string
    if target == "." or target == "/" then
        return getProjectName()
    end

    local clean = string.gsub(target, "/+$", "")
    if string.sub(clean, 1, 1) ~= "/" then
        clean = `/{clean}`
    end
    return clean
end

local function normalizeTarget(target: string): string
    if target == "/" then
        return "."
    end
    return (string.gsub(target, "^/", ""))
end

local function formatLabel(targets: { string }): string
    local parts = {}
    for _, target in targets do
        table.insert(parts, formatTarget(target))
    end
    return table.concat(parts, ", ")
end

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
        table.insert(args, normalizeTarget(target))
    end

    local result = process.exec("luau-lsp", args)
    printOutput(result)

    if result.ok then
        print(`No errors found in {label}.`)
    end

    return result.ok
end

export type Platform = {
    Platform: string,
    Targets: { string },
    Sourcemap: string?,
    RojoProject: string?,
    IgnorePatterns: { string }?,
}

export type LintConfig = {
    Platforms: { Platform }?,
    IgnorePatterns: { string }?,
}

function Lint.run(config: LintConfig?)
    local cfg = config or {}
    local ignoreArgs = buildIgnoreArgs(cfg.IgnorePatterns)

    local platforms: { Platform } = cfg.Platforms or {
        { Platform = "lune", Targets = { "." } },
    }

    local allPassed = true

    for _, entry in platforms do
        local sourcemap = entry.Sourcemap

        if not sourcemap and entry.RojoProject then
            sourcemap = "sourcemap.json"
            generateSourcemap(entry.RojoProject, sourcemap)
        end

        local entryIgnoreArgs = ignoreArgs
        if entry.IgnorePatterns then
            entryIgnoreArgs = buildIgnoreArgs(cfg.IgnorePatterns)
            for _, pattern in entry.IgnorePatterns :: { string } do
                table.insert(entryIgnoreArgs, `--ignore={pattern}`)
            end
        end

        local label = formatLabel(entry.Targets)
        if not analyze(label, entry.Platform, entry.Targets, sourcemap, entryIgnoreArgs) then
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
