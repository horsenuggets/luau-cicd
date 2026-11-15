#!/usr/bin/env -S lune run

--[[

CheckNoTabs.exec

Validates that no Luau files contain tab characters. All indentation must use spaces.

[Usage] ./Scripts/CheckNoTabs.exec.luau [directory]
> directory → Optional directory to check. Defaults to the current directory.

--]]

const IsExcludedPath = require("./Helpers/IsExcludedPath.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const function findTabsInFile(content: string): { number }
    assert(type(content) == "string", "Expected a string for the file content.")

    const linesWithTabs: { number } = {}
    local lineNum = 1

    for line in string.gmatch(`{content}\n`, "([^\n]*)\n") do
        if string.find(line, "\t", 1, true) then
            table.insert(linesWithTabs, lineNum)
        end
        lineNum += 1
    end

    return linesWithTabs
end

const function findLuauFiles(directory: string, scanningRepoRoot: boolean): { string }
    assert(type(directory) == "string", "Expected a string for the directory.")
    assert(type(scanningRepoRoot) == "boolean", "Expected a boolean for scanning the repository root.")

    const files: { string } = {}

    const function scanDir(dir: string)
        assert(type(dir) == "string", "Expected a string for the directory.")

        const entries = fs.readDir(dir)
        table.sort(entries)

        for _, entry in entries do
            const fullPath = `{dir}/{entry}`
            const relativePath = string.sub(fullPath, #directory + 2)

            if fs.isDir(fullPath) then
                if not IsExcludedPath(`{relativePath}/`, scanningRepoRoot) then
                    scanDir(fullPath)
                end
            elseif fs.isFile(fullPath) and string.match(entry, "%.luau$") then
                if not IsExcludedPath(relativePath, scanningRepoRoot) then
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

    print(`Checking for tabs in "{directory}"...`)

    if not fs.isDir(directory) then
        print(`Directory "{directory}" was not found.`)
        process.exit(1)
    end

    -- Skip root-only folders such as Build/ only when scanning the whole repository.
    const scanningRepoRoot = process.args[1] == nil or process.args[1] == "."
    const files = findLuauFiles(directory, scanningRepoRoot)
    const errors: { { File: string, Lines: { number } } } = {}

    for _, filepath in files do
        const content = fs.readFile(filepath)
        const linesWithTabs = findTabsInFile(content)
        if #linesWithTabs > 0 then
            const relativePath = string.sub(filepath, #directory + 2)
            table.insert(errors, { File = relativePath, Lines = linesWithTabs })
        end
    end

    if #errors > 0 then
        print(`Found {#errors} {if #errors == 1 then "file" else "files"} with tabs...`)
        print("")
        for _, err in errors do
            const lineList = table.concat(err.Lines, ", ")
            print(`  "{err.File}"`)
            print(`    Tabs appear on {if #err.Lines == 1 then "line" else "lines"} {lineList}.`)
            print("")
        end
        process.exit(1)
    end

    print(`Validated space-only indentation in {#files} {if #files == 1 then "file" else "files"}.`)
end

CheckNoTabs.exec()
