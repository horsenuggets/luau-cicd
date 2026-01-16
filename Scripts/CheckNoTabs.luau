#!/usr/bin/env -S lune run

--[[

CheckNoTabs

Validates that no Luau files contain tab characters. All indentation must use spaces.

Usage: lune run CheckNoTabs [directory]
  directory: Optional path to the directory to check. Defaults to current directory.

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

local function findTabsInFile(content: string): { number }
    local linesWithTabs: { number } = {}
    local lineNum = 1

    for line in string.gmatch(content .. "\n", "([^\n]*)\n") do
        if string.find(line, "\t", 1, true) then
            table.insert(linesWithTabs, lineNum)
        end
        lineNum += 1
    end

    return linesWithTabs
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

local function checkNoTabs()
    local directory = process.args[1] or process.cwd

    print(`Checking for tabs in {directory}...`)

    if not fs.isDir(directory) then
        print(`Directory not found: {directory}`)
        process.exit(1)
    end

    local files = findLuauFiles(directory)
    local errors: { { file: string, lines: { number } } } = {}

    for _, filepath in files do
        local content = fs.readFile(filepath)
        local linesWithTabs = findTabsInFile(content)
        if #linesWithTabs > 0 then
            local relativePath = string.sub(filepath, #directory + 2)
            table.insert(errors, { file = relativePath, lines = linesWithTabs })
        end
    end

    if #errors > 0 then
        print(`Found {#errors} file(s) with tabs:`)
        print("")
        for _, e in errors do
            local lineList = table.concat(e.lines, ", ")
            print(`  {e.file}`)
            print(`    Lines with tabs: {lineList}`)
            print("")
        end
        process.exit(1)
    end

    print(`All {#files} file(s) use spaces for indentation.`)
end

checkNoTabs()
