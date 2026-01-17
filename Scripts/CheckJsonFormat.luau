--[[

CheckJsonFormat

Validates that all JSON files are formatted according to project standards using Prettier.
Ensures consistent 4-space indentation as specified in .editorconfig.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local EXCLUDED_DIRS = {
    "DevPackages",
    "Packages",
    "node_modules",
    "Submodules",
}

local function isExcluded(path: string): boolean
    for _, excluded in EXCLUDED_DIRS do
        if string.find(path, excluded, 1, true) then
            return true
        end
    end
    return false
end

local function findJsonFiles(dir: string): { string }
    local files: { string } = {}

    local function traverse(currentDir: string)
        local entries = fs.readDir(currentDir)

        for _, entry in entries do
            local path = `{currentDir}/{entry}`

            if isExcluded(path) then
                continue
            end

            if fs.isDir(path) then
                traverse(path)
            elseif fs.isFile(path) and string.match(entry, "%.json$") then
                table.insert(files, path)
            end
        end
    end

    traverse(dir)
    table.sort(files)
    return files
end

local function checkPrettierInstalled(): boolean
    local result = process.exec("prettier", { "--version" })
    return result.ok
end

local function checkJsonFormat()
    print("Checking JSON formatting...")

    if not checkPrettierInstalled() then
        print("Prettier is not installed. Install it with 'npm install -g prettier'.")
        process.exit(1)
    end

    local jsonFiles = findJsonFiles(".")

    if #jsonFiles == 0 then
        print("No JSON files found to check.")
        return
    end

    print(`Found {#jsonFiles} JSON file(s) to check.`)

    -- Build prettier arguments: --check --tab-width 4 <files>
    local args = { "--check", "--tab-width", "4" }
    for _, file in jsonFiles do
        table.insert(args, file)
    end

    local result = process.exec("prettier", args)

    if result.ok then
        print("JSON formatting check passed!")
        process.exit(0)
    else
        print("JSON formatting check failed.")
        print("")
        if result.stdout ~= "" then
            print(result.stdout)
        end
        if result.stderr ~= "" then
            print(result.stderr)
        end
        print("")
        print("Run 'prettier --write --tab-width 4 <file>' to fix formatting.")
        process.exit(1)
    end
end

checkJsonFormat()
