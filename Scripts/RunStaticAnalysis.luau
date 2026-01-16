--[[

RunStaticAnalysis

Runs luau-lsp static analysis with shebang handling. Since luau-lsp does not support
shebangs, this script temporarily strips them from files before analysis and restores
them afterward.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local EXCLUDED_PATHS = {
    "DevPackages/",
    "Packages/",
    "Submodules/",
    "node_modules/",
}

local function isExcluded(path: string): boolean
    for _, excluded in EXCLUDED_PATHS do
        if string.find(path, excluded, 1, true) then
            return true
        end
    end
    return false
end

local function findLuauFiles(directory: string): { string }
    local files: { string } = {}

    local function scanDir(dir: string)
        local entries = fs.readDir(dir)
        table.sort(entries)

        for _, entry in entries do
            local fullPath = dir .. "/" .. entry
            local relativePath = string.sub(fullPath, #directory + 2)

            if fs.isDir(fullPath) then
                if not isExcluded(relativePath .. "/") then
                    scanDir(fullPath)
                end
            elseif fs.isFile(fullPath) and string.match(entry, "%.luau$") then
                if not isExcluded(relativePath) then
                    table.insert(files, fullPath)
                end
            end
        end
    end

    scanDir(directory)
    return files
end

local function hasShebang(content: string): boolean
    return string.sub(content, 1, 2) == "#!"
end

local function stripShebang(content: string): (string, string?)
    if not hasShebang(content) then
        return content, nil
    end

    local newlinePos = string.find(content, "\n")
    if not newlinePos then
        -- Entire file is just a shebang
        return "", content
    end

    local shebang = string.sub(content, 1, newlinePos)
    local rest = string.sub(content, newlinePos + 1)
    return rest, shebang
end

local function runStaticAnalysis()
    local directory = process.cwd

    print(`Running static analysis in "{directory}"...`)

    local files = findLuauFiles(directory)
    local shebangs: { [string]: string } = {}

    -- Strip shebangs from files
    for _, filepath in files do
        local content = fs.readFile(filepath)
        if hasShebang(content) then
            local stripped, shebang = stripShebang(content)
            shebangs[filepath] = shebang :: string
            fs.writeFile(filepath, stripped)
        end
    end

    local shebangCount = 0
    for _ in shebangs do
        shebangCount += 1
    end

    if shebangCount > 0 then
        print(`Temporarily stripped shebangs from {shebangCount} file(s).`)
    end

    -- Run luau-lsp analyze
    local result = process.exec("luau-lsp", {
        "analyze",
        "--platform",
        "standard",
        "--ignore",
        "DevPackages/**",
        "--ignore",
        "Packages/**",
        "--ignore",
        "Submodules/**",
        ".",
    })

    -- Restore shebangs
    for filepath, shebang in shebangs do
        local content = fs.readFile(filepath)
        fs.writeFile(filepath, shebang .. content)
    end

    if shebangCount > 0 then
        print(`Restored shebangs to {shebangCount} file(s).`)
    end

    if result.ok then
        print("Static analysis passed!")
        process.exit(0)
    else
        print("Static analysis failed.")
        print(result.stdout)
        print(result.stderr)
        process.exit(1)
    end
end

runStaticAnalysis()
