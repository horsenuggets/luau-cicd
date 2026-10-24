#!/usr/bin/env -S lune run

--[[

CheckNoTabs.exec

Validates that no Luau files contain tab characters. All indentation must use spaces.

[Usage] ./Scripts/CheckNoTabs.exec.luau [directory]
> directory - Optional path to the directory to check. Defaults to current
> directory.

--]]

const fs = require("@lune/fs")
const isExcluded = require("./Helpers/isExcludedPath")
const process = require("@lune/process")

const function findTabsInFile(content: string): { number }
    const linesWithTabs: { number } = {}
    local lineNum = 1

    for line in string.gmatch(content .. "\n", "([^\n]*)\n") do
        if string.find(line, "\t", 1, true) then
            table.insert(linesWithTabs, lineNum)
        end
        lineNum += 1
    end

    return linesWithTabs
end

const function findLuauFiles(directory: string, scanningRepoRoot: boolean): { string }
    const files: { string } = {}

    const function scanDir(dir: string)
        const entries = fs.readDir(dir)
        table.sort(entries)

        for _, entry in entries do
            const fullPath = dir .. "/" .. entry
            const relativePath = string.sub(fullPath, #directory + 2)

            if fs.isDir(fullPath) then
                if not isExcluded(relativePath .. "/", scanningRepoRoot) then
                    scanDir(fullPath)
                end
            elseif fs.isFile(fullPath) and string.match(entry, "%.luau$") then
                if not isExcluded(relativePath, scanningRepoRoot) then
                    table.insert(files, fullPath)
                end
            end
        end
    end

    scanDir(directory)
    return files
end

const CheckNoTabs = {}

function CheckNoTabs.exec()
    const directory = process.args[1] or process.cwd

    print(`Checking for tabs in {directory}...`)

    if not fs.isDir(directory) then
        print(`Directory not found: {directory}`)
        process.exit(1)
    end

    -- Root-only folders like Build/ are only skipped when the whole repo is scanned
    const scanningRepoRoot = process.args[1] == nil or process.args[1] == "."
    const files = findLuauFiles(directory, scanningRepoRoot)
    const errors: { { file: string, lines: { number } } } = {}

    for _, filepath in files do
        const content = fs.readFile(filepath)
        const linesWithTabs = findTabsInFile(content)
        if #linesWithTabs > 0 then
            const relativePath = string.sub(filepath, #directory + 2)
            table.insert(errors, { file = relativePath, lines = linesWithTabs })
        end
    end

    if #errors > 0 then
        print(`Found {#errors} file(s) with tabs:`)
        print("")
        for _, e in errors do
            const lineList = table.concat(e.lines, ", ")
            print(`  {e.file}`)
            print(`    Lines with tabs: {lineList}`)
            print("")
        end
        process.exit(1)
    end

    print(`All {#files} file(s) use spaces for indentation.`)
end

CheckNoTabs.exec()
