--[[

TestEnvironment

Helper module for creating isolated test environments with temp directories.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local TestEnvironment = {}

export type ExecResult = {
    ok: boolean,
    code: number,
    stdout: string,
    stderr: string,
}

export type Environment = {
    path: string,
    cleanup: () -> (),
    writeDir: (relativePath: string) -> (),
    writeFile: (relativePath: string, content: string) -> (),
    readFile: (relativePath: string) -> string,
    fileExists: (relativePath: string) -> boolean,
    runScript: (scriptName: string, args: { string }?) -> ExecResult,
    initGit: () -> (),
    gitCommit: (message: string) -> (),
    gitTag: (tag: string) -> (),
}

function TestEnvironment.create(): Environment
    local timestamp = tostring(os.time()) .. tostring(math.random(10000, 99999))
    local tempDir = `/tmp/luau-cicd-test-{timestamp}`
    fs.writeDir(tempDir)

    -- Get the absolute path to the Scripts directory
    local scriptsDir = process.cwd .. "/Scripts"

    -- Copy rokit.toml to temp dir so rokit-managed tools work
    if fs.isFile("rokit.toml") then
        fs.copy("rokit.toml", `{tempDir}/rokit.toml`)
    end

    local env: Environment = {
        path = tempDir,

        cleanup = function()
            if fs.isDir(tempDir) then
                process.exec("rm", { "-rf", tempDir })
            end
        end,

        writeDir = function(relativePath: string)
            fs.writeDir(`{tempDir}/{relativePath}`)
        end,

        writeFile = function(relativePath: string, content: string)
            local fullPath = `{tempDir}/{relativePath}`
            local dir = string.match(fullPath, "(.+)/[^/]+$")
            if dir and not fs.isDir(dir) then
                fs.writeDir(dir)
            end
            fs.writeFile(fullPath, content)
        end,

        readFile = function(relativePath: string): string
            return fs.readFile(`{tempDir}/{relativePath}`)
        end,

        fileExists = function(relativePath: string): boolean
            return fs.isFile(`{tempDir}/{relativePath}`)
        end,

        runScript = function(scriptName: string, args: { string }?): ExecResult
            local scriptPath = `{scriptsDir}/{scriptName}.luau`
            local luneArgs = { "run", scriptPath }
            if args then
                for _, arg in args do
                    table.insert(luneArgs, arg)
                end
            end
            return process.exec("lune", luneArgs, { cwd = tempDir })
        end,

        initGit = function()
            process.exec("git", { "init" }, { cwd = tempDir })
            process.exec("git", { "config", "user.email", "test@test.com" }, { cwd = tempDir })
            process.exec("git", { "config", "user.name", "Test User" }, { cwd = tempDir })
        end,

        gitCommit = function(message: string)
            process.exec("git", { "add", "-A" }, { cwd = tempDir })
            process.exec("git", { "commit", "-m", message, "--allow-empty" }, { cwd = tempDir })
        end,

        gitTag = function(tag: string)
            process.exec("git", { "tag", tag }, { cwd = tempDir })
        end,
    }

    return env
end

return TestEnvironment
