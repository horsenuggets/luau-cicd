#!/usr/bin/env -S lune run

--[[

CheckFileHeaders

Validates that all Luau files have properly formatted header comments. Supports optional
directives (like --!strict, --!native) or shebangs at the top of the file, followed by a
blank line, then the header comment block.

Usage: lune run CheckFileHeaders [directory]
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

local function isExcludedFile(filename: string, relativePath: string): boolean
    -- Root init.luau is excluded (just a re-export)
    if filename == "init.luau" and not string.find(relativePath, "/", 1, true) then
        return true
    end
    return false
end

local function getExpectedName(filepath: string): string
    local filename = string.match(filepath, "([^/]+)%.luau$")
    if filename == "init" then
        -- For init.luau, use the parent folder name
        local parentFolder = string.match(filepath, "([^/]+)/init%.luau$")
        return parentFolder or "init"
    end
    -- Strip .spec suffix for test files
    if string.match(filename or "", "%.spec$") then
        filename = string.match(filename, "(.+)%.spec$")
    end
    return filename or ""
end

local function isDirective(line: string): boolean
    -- Luau directives: --!strict, --!nonstrict, --!nocheck, --!native, --!optimize
    -- Shebangs: #!/usr/bin/env lune
    return string.match(line, "^%-%-!") ~= nil or string.match(line, "^#!") ~= nil
end

local function validateHeader(filepath: string, content: string): string?
    local lines: { string } = {}
    for line in string.gmatch(content .. "\n", "([^\n]*)\n") do
        table.insert(lines, line)
    end

    if #lines == 0 then
        return "File is empty."
    end

    local lineIndex = 1

    -- Skip directives at the top
    local hasDirectives = false
    while lineIndex <= #lines and isDirective(lines[lineIndex]) do
        hasDirectives = true
        lineIndex += 1
    end

    -- If there were directives, require a blank line after them
    if hasDirectives then
        if lineIndex > #lines then
            return "File has directives but no header comment."
        end
        if lines[lineIndex] ~= "" then
            return "Expected blank line after directives, found: " .. lines[lineIndex]
        end
        lineIndex += 1
    end

    -- Now we should have the header block
    if lineIndex > #lines then
        return "Missing header comment."
    end

    -- Line: --[[
    if lines[lineIndex] ~= "--[[" then
        return `Expected "--[[" at line {lineIndex}, found: "{lines[lineIndex]}".`
    end
    lineIndex += 1

    -- Line: (blank)
    if lineIndex > #lines or lines[lineIndex] ~= "" then
        return `Expected blank line after "--[[" at line {lineIndex}.`
    end
    lineIndex += 1

    -- Line: Module name
    if lineIndex > #lines then
        return "Missing module name in header."
    end
    local moduleName = lines[lineIndex]
    if moduleName == "" then
        return `Expected module name at line {lineIndex}, found blank line.`
    end

    local expectedName = getExpectedName(filepath)
    if moduleName ~= expectedName then
        return `Module name "{moduleName}" does not match expected "{expectedName}" at line {lineIndex}.`
    end
    lineIndex += 1

    -- Line: (blank)
    if lineIndex > #lines or lines[lineIndex] ~= "" then
        return `Expected blank line after module name at line {lineIndex}.`
    end
    lineIndex += 1

    -- Lines: Description/content (at least one non-blank line before --]])
    -- Content can have multiple paragraphs separated by blank lines
    -- Must end with a blank line before --]]
    if lineIndex > #lines or lines[lineIndex] == "" or lines[lineIndex] == "--]]" then
        return `Expected description at line {lineIndex}.`
    end

    local hasContent = false
    local prevLineWasBlank = false

    while lineIndex <= #lines do
        local line = lines[lineIndex]

        -- Check if we've reached the closing
        if line == "--]]" then
            if not prevLineWasBlank then
                return `Expected blank line before "--]]" at line {lineIndex}.`
            end
            break
        end

        -- Check line length for non-blank lines (should wrap at column 90)
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

    -- Verify we found --]]
    if lineIndex > #lines or lines[lineIndex] ~= "--]]" then
        return `Expected "--]]" at line {lineIndex}.`
    end

    return nil -- No errors
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
                if not isExcluded(relativePath) and not isExcludedFile(entry, relativePath) then
                    table.insert(files, fullPath)
                end
            end
        end
    end

    scanDir(directory)
    return files
end

local function checkFileHeaders()
    local directory = process.args[1] or process.cwd

    print(`Checking file headers in {directory}...`)

    if not fs.isDir(directory) then
        print(`Directory not found: {directory}`)
        process.exit(1)
    end

    local files = findLuauFiles(directory)
    local errors: { { file: string, error: string } } = {}

    for _, filepath in files do
        local content = fs.readFile(filepath)
        local err = validateHeader(filepath, content)
        if err then
            local relativePath = string.sub(filepath, #directory + 2)
            table.insert(errors, { file = relativePath, error = err })
        end
    end

    if #errors > 0 then
        print(`Found {#errors} file(s) with invalid headers:`)
        print("")
        for _, e in errors do
            print(`  {e.file}`)
            print(`    {e.error}`)
            print("")
        end
        process.exit(1)
    end

    print(`All {#files} file(s) have valid headers.`)
end

checkFileHeaders()
