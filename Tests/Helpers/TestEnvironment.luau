--[[

TestEnvironment

Creates isolated test environments with temporary directories.

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")

const TestEnvironment = {}

const function dedent(str: string): string
    assert(typeof(str) == "string", "Expected a string.")

    -- Remove the leading newline if present.
    const content = string.match(str, "^\n(.*)$") or str

    -- Find the minimum indentation, ignoring empty lines.
    local minIndent = math.huge
    for line in string.gmatch(content, "[^\n]+") do
        const indent = string.match(line, "^(%s*)")
        if indent and #line > #indent then
            minIndent = math.min(minIndent, #indent)
        end
    end

    if minIndent == math.huge then
        minIndent = 0
    end

    -- Remove that amount of indentation from each line.
    const lines = {}
    for line in string.gmatch(`{content}\n`, "([^\n]*)\n") do
        if #line > 0 then
            table.insert(lines, string.sub(line, minIndent + 1))
        else
            table.insert(lines, line)
        end
    end

    return table.concat(lines, "\n")
end

TestEnvironment.dedent = dedent

-- Quotes a string for a test name, escaping control characters so names stay on one line.
function TestEnvironment.quote(str: string): string
    assert(typeof(str) == "string", "Expected a string.")

    const escaped = string.gsub(str, '[%c\\"]', function(char: string): string
        if char == "\n" then
            return "\\n"
        elseif char == "\r" then
            return "\\r"
        elseif char == "\t" then
            return "\\t"
        elseif char == "\\" or char == '"' then
            return `\\{char}`
        end
        return string.format("\\x%02X", string.byte(char))
    end)
    return `"{escaped}"`
end

export type ExecResult = process.ExecResult

export type Environment = {
    Cleanup: () -> (),
    FileExists: (relativePath: string) -> boolean,
    GitCommit: (message: string) -> (),
    GitTag: (tag: string) -> (),
    InitGit: () -> (),
    Path: string,
    ReadFile: (relativePath: string) -> string,
    RunScript: (scriptName: string, args: { string }?, extraEnv: { [string]: string }?) -> ExecResult,
    WriteDir: (relativePath: string) -> (),
    WriteFile: (relativePath: string, content: string) -> ()
}

function TestEnvironment.create(): Environment
    const timestamp = `{os.time()}{math.random(10000, 99999)}`
    const tempDir = `/tmp/luau-cicd-test-{timestamp}`
    fs.writeDir(tempDir)

    -- Get the absolute path to the scripts directory.
    const scriptsDir = `{process.cwd}/Scripts`

    -- Copy "rokit.toml" so Rokit-managed tools work in the temporary directory.
    if fs.isFile("rokit.toml") then
        fs.copy("rokit.toml", `{tempDir}/rokit.toml`)
    end

    const env: Environment = {
        Cleanup = function()
            if fs.isDir(tempDir) then
                process.exec("rm", { "-rf", tempDir })
            end
        end,
        FileExists = function(relativePath: string): boolean
            assert(typeof(relativePath) == "string", "Expected a relative path string.")

            return fs.isFile(`{tempDir}/{relativePath}`)
        end,
        GitCommit = function(message: string)
            assert(typeof(message) == "string", "Expected a commit message string.")

            process.exec("git", { "add", "-A" }, { cwd = tempDir })
            process.exec("git", { "commit", "-m", message, "--allow-empty" }, { cwd = tempDir })
        end,
        GitTag = function(tag: string)
            assert(typeof(tag) == "string", "Expected a tag string.")

            process.exec("git", { "tag", tag }, { cwd = tempDir })
        end,
        InitGit = function()
            process.exec("git", { "init" }, { cwd = tempDir })
            process.exec("git", { "config", "user.email", "test@example.com" }, { cwd = tempDir })
            process.exec("git", { "config", "user.name", "Test User" }, { cwd = tempDir })
        end,
        Path = tempDir,
        ReadFile = function(relativePath: string): string
            assert(typeof(relativePath) == "string", "Expected a relative path string.")

            return fs.readFile(`{tempDir}/{relativePath}`)
        end,
        RunScript = function(scriptName: string, args: { string }?, extraEnv: { [string]: string }?): ExecResult
            assert(typeof(scriptName) == "string", "Expected a script name string.")
            assert(args == nil or typeof(args) == "table", "Expected an optional argument array.")
            assert(extraEnv == nil or typeof(extraEnv) == "table", "Expected an optional environment table.")

            const scriptPath = `{scriptsDir}/{scriptName}.exec.luau`
            const luneArgs = { "run", scriptPath }
            if args then
                for _, arg in args do
                    assert(typeof(arg) == "string", "Expected string arguments.")
                    table.insert(luneArgs, arg)
                end
            end
            return process.exec("lune", luneArgs, { cwd = tempDir, env = extraEnv })
        end,
        WriteDir = function(relativePath: string)
            assert(typeof(relativePath) == "string", "Expected a relative path string.")

            fs.writeDir(`{tempDir}/{relativePath}`)
        end,
        WriteFile = function(relativePath: string, content: string)
            assert(typeof(relativePath) == "string", "Expected a relative path string.")
            assert(typeof(content) == "string", "Expected file content as a string.")

            const fullPath = `{tempDir}/{relativePath}`
            const dir = string.match(fullPath, "(.+)/[^/]+$")
            if dir and not fs.isDir(dir) then
                fs.writeDir(dir)
            end
            fs.writeFile(fullPath, content)
        end
    }

    return env
end

return TestEnvironment
