#!/usr/bin/env -S lune run

--[[

CheckJsonFormat.exec

Validates that all JSON files are formatted according to project standards using Prettier.
Ensures consistent 4-space indentation as specified in .editorconfig.

--]]

const IsExcludedPath = require("./Helpers/IsExcludedPath.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const function findJsonFiles(dir: string): { string }
    assert(type(dir) == "string", "Expected a string for the directory.")

    const files: { string } = {}

    const function traverse(currentDir: string)
        assert(type(currentDir) == "string", "Expected a string for the directory.")

        const entries = fs.readDir(currentDir)

        for _, entry in entries do
            const path = `{currentDir}/{entry}`

            -- Skip root-only folders because this check always scans the repository root.
            if IsExcludedPath(path, true) then
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
        print('Prettier is not installed. Install it with "npm install -g prettier".')
        process.exit(1)
    end

    const jsonFiles = findJsonFiles(".")

    if #jsonFiles == 0 then
        print("No JSON files found to check.")
        return
    end

    print(`Found {#jsonFiles} JSON {if #jsonFiles == 1 then "file" else "files"} to check.`)

    -- Build Prettier arguments with the required indentation width.
    const args = { "--check", "--tab-width", "4" }
    for _, file in jsonFiles do
        table.insert(args, file)
    end

    const result = process.exec("prettier", args)

    if result.ok then
        print("JSON formatting check passed.")
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
        print('Run "prettier --write --tab-width 4 <file>" to fix formatting.')
        process.exit(1)
    end
end

CheckJsonFormat.exec()
