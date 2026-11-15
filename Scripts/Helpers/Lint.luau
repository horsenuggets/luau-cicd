--[[

Lint

Runs luau-lsp analyze for downstream repositories through the luau-cicd submodule instead
of maintaining separate lint logic in each repository.

By default, analyzes "." with --platform=lune, --no-flags-enabled, and
--enable-new-solver, ignoring DevPackages/, Packages/, ServerPackages/, Submodules/, and
dotfolders. Accepts an optional config table to override platforms, ignore patterns, and
target directories.

--]]

const process = require("@lune/process")

const DEFAULT_IGNORE_PATTERNS = {
    ".*/**",
    "DevPackages/**",
    "Packages/**",
    "ServerPackages/**",
    "Submodules/**",
}

const Lint = {}

const function getProjectName(): string
    const cwd = process.cwd
    const name = string.match(cwd, "([^/]+)/?$")
    return name or "."
end

const function formatTarget(target: string): string
    assert(type(target) == "string", "Expected a string for the target.")

    if target == "." or target == "/" then
        return getProjectName()
    end

    local clean = string.gsub(target, "/+$", "")
    if string.sub(clean, 1, 1) ~= "/" then
        clean = `/{clean}`
    end
    return clean
end

const function normalizeTarget(target: string): string
    assert(type(target) == "string", "Expected a string for the target.")

    if target == "/" then
        return "."
    end
    return (string.gsub(target, "^/", ""))
end

const function formatLabel(targets: { string }): string
    assert(type(targets) == "table", "Expected an array of targets.")

    const parts = {}
    for _, target in targets do
        table.insert(parts, formatTarget(target))
    end
    return table.concat(parts, ", ")
end

const function printOutput(result: process.ExecResult)
    assert(type(result) == "table", "Expected a process result.")
    assert(type(result.stdout) == "string", "Expected a string for standard output.")
    assert(type(result.stderr) == "string", "Expected a string for standard error.")

    if result.stdout ~= "" then
        print(result.stdout)
    end
    if result.stderr ~= "" then
        print(result.stderr)
    end
end

const function generateSourcemap(rojoProject: string, outputFile: string)
    assert(type(rojoProject) == "string", "Expected a string for the Rojo project.")
    assert(type(outputFile) == "string", "Expected a string for the output file.")

    const result = process.exec("rojo", {
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

const function buildIgnoreArgs(extraPatterns: { string }?): { string }
    assert(extraPatterns == nil or type(extraPatterns) == "table", "Expected an optional array of ignore patterns.")

    const args = {}

    for _, pattern in DEFAULT_IGNORE_PATTERNS do
        table.insert(args, `--ignore={pattern}`)
    end

    if extraPatterns then
        for _, pattern in extraPatterns do
            assert(type(pattern) == "string", "Expected a string for each ignore pattern.")
            table.insert(args, `--ignore={pattern}`)
        end
    end

    return args
end

const function analyze(
    label: string,
    platform: string,
    targets: { string },
    sourcemap: string?,
    ignoreArgs: { string }
): boolean
    assert(type(label) == "string", "Expected a string for the label.")
    assert(type(platform) == "string", "Expected a string for the platform.")
    assert(type(targets) == "table", "Expected an array of targets.")
    assert(sourcemap == nil or type(sourcemap) == "string", "Expected an optional string for the sourcemap.")
    assert(type(ignoreArgs) == "table", "Expected an array of ignore arguments.")

    print(`Analyzing "{label}"...`)

    const args = {
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

    const result = process.exec("luau-lsp", args)
    printOutput(result)

    if result.ok then
        print(`No errors found in {label}.`)
    end

    return result.ok
end

export type Platform = {
    IgnorePatterns: { string }?,
    Platform: string,
    RojoProject: string?,
    Sourcemap: string?,
    Targets: { string },
}

export type LintConfig = {
    IgnorePatterns: { string }?,
    Platforms: { Platform }?,
}

function Lint.run(config: LintConfig?)
    assert(config == nil or type(config) == "table", "Expected an optional lint configuration table.")
    if config then
        assert(
            config.IgnorePatterns == nil or type(config.IgnorePatterns) == "table",
            "Expected an optional array of ignore patterns."
        )
        assert(config.Platforms == nil or type(config.Platforms) == "table", "Expected an optional array of platforms.")
        if config.IgnorePatterns then
            for _, pattern in config.IgnorePatterns do
                assert(type(pattern) == "string", "Expected a string for each ignore pattern.")
            end
        end
        if config.Platforms then
            for _, entry in config.Platforms do
                assert(type(entry) == "table", "Expected a configuration table for each platform.")
                assert(type(entry.Platform) == "string", "Expected a string for the platform.")
                assert(type(entry.Targets) == "table", "Expected an array of targets.")
                assert(
                    entry.IgnorePatterns == nil or type(entry.IgnorePatterns) == "table",
                    "Expected an optional array of ignore patterns."
                )
                assert(
                    entry.RojoProject == nil or type(entry.RojoProject) == "string",
                    "Expected an optional string for the Rojo project."
                )
                assert(
                    entry.Sourcemap == nil or type(entry.Sourcemap) == "string",
                    "Expected an optional string for the sourcemap."
                )
                for _, target in entry.Targets do
                    assert(type(target) == "string", "Expected a string for each target.")
                end
                if entry.IgnorePatterns then
                    for _, pattern in entry.IgnorePatterns do
                        assert(type(pattern) == "string", "Expected a string for each ignore pattern.")
                    end
                end
            end
        end
    end

    const cfg = config or {}
    const ignoreArgs = buildIgnoreArgs(cfg.IgnorePatterns)

    const platforms: { Platform } = cfg.Platforms or {
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

        const label = formatLabel(entry.Targets)
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
