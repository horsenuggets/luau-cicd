--[[

GetReadmeVersionReferences.func

Finds a package's version references in README content. Returns the version text and its
inclusive bounds, leaving sentence-ending periods outside each reference.

--]]

export type Reference = {
    End: number,
    Start: number,
    Version: string,
}

const function GetReadmeVersionReferences(content: string, packageName: string): { Reference }
    assert(type(content) == "string", "Expected README content as a string.")
    assert(type(packageName) == "string", "Expected a package name string.")

    const escapedPackageName = string.gsub(packageName, "([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
    const pattern = `%f[%w_./%-]{escapedPackageName}@()(%d[%w%.%+%-]*)()`
    const references: { Reference } = {}

    for startIndex, candidate, endIndex in string.gmatch(content, pattern) do
        const version = string.gsub(candidate, "%.+$", "")
        table.insert(references, {
            End = endIndex - 1 - (#candidate - #version),
            Start = startIndex,
            Version = version,
        })
    end

    return references
end

return GetReadmeVersionReferences
