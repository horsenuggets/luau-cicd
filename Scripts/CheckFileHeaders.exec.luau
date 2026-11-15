#!/usr/bin/env -S lune run

--[[

CheckFileHeaders.exec

Validates that all Luau files have properly formatted header comments. Supports optional
directives (like --!strict, --!native) or shebangs at the top of the file, followed by a
blank line, then the header comment block.

[Usage] ./Scripts/CheckFileHeaders.exec.luau [directory]
> directory → Optional directory to check. Defaults to the current directory.

--]]

const IsExcludedPath = require("./Helpers/IsExcludedPath.func")
const fs = require("@lune/fs")
const process = require("@lune/process")

const function isExcludedFile(filename: string, relativePath: string): boolean
    assert(type(filename) == "string", "Expected a string for the file name.")
    assert(type(relativePath) == "string", "Expected a string for the relative path.")

    -- Exclude the root init.luau file because it is just a re-export.
    if filename == "init.luau" and not string.find(relativePath, "/", 1, true) then
        return true
    end
    return false
end

const function getExpectedName(filepath: string): string
    assert(type(filepath) == "string", "Expected a string for the file path.")

    const filename = string.match(filepath, "([^/]+)%.luau$")
    if filename == "init" or string.match(filename or "", "^init%.") then
        -- Use the parent folder name for init.luau and Rojo variants such as
        -- init.server.luau, init.client.luau, and init.plugin.luau.
        const parentFolder = string.match(filepath, "([^/]+)/init[^/]*%.luau$")
        return parentFolder or "init"
    end
    return filename or ""
end

const function isDirective(line: string): boolean
    assert(type(line) == "string", "Expected a string for the line.")

    -- Recognize Luau directives such as --!strict and executable shebang lines.
    return string.match(line, "^%-%-!") ~= nil or string.match(line, "^#!") ~= nil
end

const function validateHeader(filepath: string, content: string): string?
    assert(type(filepath) == "string", "Expected a string for the file path.")
    assert(type(content) == "string", "Expected a string for the file content.")

    const lines: { string } = {}
    for line in string.gmatch(`{content}\n`, "([^\n]*)\n") do
        table.insert(lines, line)
    end

    if #lines == 0 then
        return "File is empty."
    end

    local lineIndex = 1

    -- Skip directives at the top.
    local hasDirectives = false
    while lineIndex <= #lines and isDirective(lines[lineIndex]) do
        hasDirectives = true
        lineIndex += 1
    end

    -- Require a blank line after any directives.
    if hasDirectives then
        if lineIndex > #lines then
            return "File has directives but no header comment."
        end
        if lines[lineIndex] ~= "" then
            return `Expected a blank line after directives, found "{lines[lineIndex]}".`
        end
        lineIndex += 1
    end

    -- Check for the header block after any directives.
    if lineIndex > #lines then
        return "Missing header comment."
    end

    -- Require the opening header delimiter.
    if lines[lineIndex] ~= "--[[" then
        return `Expected "--[[" at line {lineIndex}, found "{lines[lineIndex]}".`
    end
    lineIndex += 1

    -- Require a blank separator line.
    if lineIndex > #lines or lines[lineIndex] ~= "" then
        return `Expected blank line after "--[[" at line {lineIndex}.`
    end
    lineIndex += 1

    -- Require the expected module name.
    if lineIndex > #lines then
        return "Missing module name in header."
    end
    const moduleName = lines[lineIndex]
    if moduleName == "" then
        return `Expected module name at line {lineIndex}, found blank line.`
    end

    const expectedName = getExpectedName(filepath)
    if moduleName ~= expectedName then
        return `Module name "{moduleName}" does not match expected "{expectedName}" at line {lineIndex}.`
    end
    lineIndex += 1

    -- Require a blank separator line.
    if lineIndex > #lines or lines[lineIndex] ~= "" then
        return `Expected blank line after module name at line {lineIndex}.`
    end
    lineIndex += 1

    -- Require at least one nonblank description line and a final blank separator.
    -- Allow multiple paragraphs separated by blank lines.
    if lineIndex > #lines or lines[lineIndex] == "" or lines[lineIndex] == "--]]" then
        return `Expected description at line {lineIndex}.`
    end

    local hasContent = false
    local prevLineWasBlank = false

    while lineIndex <= #lines do
        const line = lines[lineIndex]

        -- Check whether the closing delimiter has been reached.
        if line == "--]]" then
            if not prevLineWasBlank then
                return `Expected blank line before "--]]" at line {lineIndex}.`
            end
            break
        end

        -- Check that nonblank lines wrap at column 90.
        if line ~= "" and #line > 90 then
            return `Line exceeds 90 characters at line {lineIndex} ({#line} chars).`
        end

        if line ~= "" then
            hasContent = true
        end

        prevLineWasBlank = (line == "")
        lineIndex += 1
    end

    if not hasContent then
        return "Header must have a description."
    end

    -- Verify that the closing delimiter was found.
    if lineIndex > #lines or lines[lineIndex] ~= "--]]" then
        return `Expected "--]]" at line {lineIndex}.`
    end

    return nil
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
                if not IsExcludedPath(relativePath, scanningRepoRoot) and not isExcludedFile(entry, relativePath) then
                    table.insert(files, fullPath)
                end
            end
        end
    end

    scanDir(directory)
    return files
end

const CheckFileHeaders = {}

function CheckFileHeaders.exec()
    const directory = process.args[1] or process.cwd

    print(`Checking file headers in "{directory}"...`)

    if not fs.isDir(directory) then
        print(`Directory "{directory}" was not found.`)
        process.exit(1)
    end

    -- Skip root-only folders such as Build/ only when scanning the whole repository.
    const scanningRepoRoot = process.args[1] == nil or process.args[1] == "."
    const files = findLuauFiles(directory, scanningRepoRoot)
    const errors: { { Error: string, File: string } } = {}

    for _, filepath in files do
        const content = fs.readFile(filepath)
        const err = validateHeader(filepath, content)
        if err then
            const relativePath = string.sub(filepath, #directory + 2)
            table.insert(errors, { Error = err, File = relativePath })
        end
    end

    if #errors > 0 then
        print(`Found {#errors} {if #errors == 1 then "file" else "files"} with invalid headers...`)
        print("")
        for _, err in errors do
            print(`  "{err.File}"`)
            print(`    {err.Error}`)
            print("")
        end
        process.exit(1)
    end

    print(`Validated headers in {#files} {if #files == 1 then "file" else "files"}.`)
end

CheckFileHeaders.exec()
