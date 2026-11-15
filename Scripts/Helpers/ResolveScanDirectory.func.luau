--[[

ResolveScanDirectory.func

Resolves a scan directory against the working directory and identifies scans of the
working directory itself. Normalizes separators, dot components, and trailing slashes.

--]]

const function normalize(path: string): string
    const drive = string.match(path, "^%a:/")
    const share = string.match(path, "^(//[^/]+/[^/]+)/?")
    const root = drive or share or "/"
    const parts: { string } = {}

    for part in string.gmatch(string.sub(path, #root + 1), "[^/]+") do
        if part == ".." then
            if #parts > 0 then
                table.remove(parts)
            end
        elseif part ~= "." then
            table.insert(parts, part)
        end
    end

    if #parts == 0 then
        return root
    end

    return `{root}{if string.sub(root, -1) == "/" then "" else "/"}{table.concat(parts, "/")}`
end

const function ResolveScanDirectory(directory: string, workingDirectory: string): (string, boolean)
    assert(type(directory) == "string", "Expected a scan directory string.")
    assert(type(workingDirectory) == "string", "Expected a working directory string.")

    const base = normalize((string.gsub(workingDirectory, "\\", "/")))
    local path = string.gsub(directory, "\\", "/")
    if string.sub(path, 1, 1) ~= "/" and not string.match(path, "^%a:/") then
        path = `{base}/{path}`
    end
    path = normalize(path)

    const windowsPath = string.match(base, "^%a:/") ~= nil or string.sub(base, 1, 2) == "//"
    const scanningRepoRoot = if windowsPath then string.lower(path) == string.lower(base) else path == base
    return path, scanningRepoRoot
end

return ResolveScanDirectory
