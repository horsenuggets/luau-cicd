--[[

ResolveScanDirectory.func

Resolves scan directories through the filesystem before comparing them with the working
directory. Preserves parent-directory semantics when paths contain symbolic links.

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")
const WINDOWS = process.os == "windows"

const function normalize(path: string): string
    const clean = if WINDOWS then string.gsub(path, "\\", "/") else path
    const drive = string.match(clean, "^%a:/")
    const share = string.match(clean, "^(//[^/]+/[^/]+)/?")
    const root = drive or share or "/"
    const parts: { string } = {}

    for part in string.gmatch(string.sub(clean, #root + 1), "[^/]+") do
        if part ~= "." then
            table.insert(parts, part)
        end
    end

    if #parts == 0 then
        return root
    end

    return `{root}{if string.sub(root, -1) == "/" then "" else "/"}{table.concat(parts, "/")}`
end

const function resolve(path: string): string
    if not fs.isDir(path) then
        return normalize(path)
    end

    -- Resolve through the operating system without expanding the path in a shell command.
    const command = if WINDOWS then "powershell.exe" else "pwd"
    const args = if WINDOWS
        then {
            "-NoProfile",
            "-NonInteractive",
            "-Command",
            "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); [Console]::Write((Get-Location).ProviderPath)",
        }
        else { "-P" }
    const result = process.exec(command, args, { cwd = path })
    assert(result.ok, `Could not resolve scan directory "{path}". {result.stderr}`)
    return normalize(if WINDOWS then result.stdout else (string.gsub(result.stdout, "\n$", "")))
end

const function ResolveScanDirectory(directory: string, workingDirectory: string): (string, boolean)
    assert(type(directory) == "string", "Expected a scan directory string.")
    assert(type(workingDirectory) == "string", "Expected a working directory string.")

    const base = resolve(workingDirectory)
    local path = if WINDOWS then string.gsub(directory, "\\", "/") else directory
    if string.sub(path, 1, 1) ~= "/" and not (WINDOWS and string.match(path, "^%a:/")) then
        path = `{base}/{path}`
    end
    path = resolve(path)

    const scanningRepoRoot = if WINDOWS then string.lower(path) == string.lower(base) else path == base
    return path, scanningRepoRoot
end

return ResolveScanDirectory
