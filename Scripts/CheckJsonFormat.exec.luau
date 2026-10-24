#!/usr/bin/env -S lune run

--[[

CheckJsonFormat.exec

Validates that all JSON files are formatted according to project standards using Prettier.
Ensures consistent 4-space indentation as specified in .editorconfig.

--]]

const fs = require("@lune/fs")
const isExcluded = require("./Helpers/isExcludedPath")
const process = require("@lune/process")

const function findJsonFiles(dir: string): { string }
    const files: { string } = {}

    const function traverse(currentDir: string)
        const entries = fs.readDir(currentDir)

        for _, entry in entries do
            const path = `{currentDir}/{entry}`

            -- This check always scans the repo root, so root-only folders are skipped too
            if isExcluded(path, true) then
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

const function checkPrettierInstalled(): boolean
    const result = process.exec("prettier", { "--version" })
    return result.ok
end

const CheckJsonFormat = {}

function CheckJsonFormat.exec()
    print("Checking JSON formatting...")

    if not checkPrettierInstalled() then
        print("Prettier is not installed. Install it with 'npm install -g prettier'.")
        process.exit(1)
    end

    const jsonFiles = findJsonFiles(".")

    if #jsonFiles == 0 then
        print("No JSON files found to check.")
        return
    end

    print(`Found {#jsonFiles} JSON file(s) to check.`)

    -- Build prettier arguments: --check --tab-width 4 <files>
    const args = { "--check", "--tab-width", "4" }
    for _, file in jsonFiles do
        table.insert(args, file)
    end

    const result = process.exec("prettier", args)

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

CheckJsonFormat.exec()
