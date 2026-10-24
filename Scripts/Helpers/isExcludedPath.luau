--[[

isExcludedPath

Decides whether a path should be skipped by the checks that scan files. The path is
relative to the folder being scanned. Dependency and submodule folders are skipped at any
depth. Generated output (Build/) and worktree folders (.wt/, .worktrees/) only exist at
the repo root, so they're skipped only when the scan starts there, which keeps a source
folder that happens to be named Build checked. Path parts are compared whole, so a folder
like MyPackages isn't mistaken for Packages.

--]]

const EXCLUDED_FOLDERS = { "DevPackages", "node_modules", "Packages", "ServerPackages", "Submodules" }
const EXCLUDED_ROOT_FOLDERS = { ".worktrees", ".wt", "Build" }

const function isExcludedPath(relativePath: string, scanningRepoRoot: boolean): boolean
    assert(typeof(relativePath) == "string", "Expected a string.")
    assert(typeof(scanningRepoRoot) == "boolean", "Expected a boolean.")

    const path = string.gsub(string.gsub(relativePath, "\\", "/"), "^%./", "")
    local index = 0
    for part in string.gmatch(path, "[^/]+") do
        index += 1
        if table.find(EXCLUDED_FOLDERS, part) then
            return true
        end
        if scanningRepoRoot and index == 1 and table.find(EXCLUDED_ROOT_FOLDERS, part) then
            return true
        end
    end
    return false
end

return isExcludedPath
