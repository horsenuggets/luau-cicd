--[[

isExcludedPath

Decides whether a repo-relative path should be skipped by the checks that scan files.
Dependency and submodule folders are skipped at any depth, while generated output
(Build/) and worktree folders (.wt/, .worktrees/) are only skipped at the repo root, so a
source folder that happens to be named Build is still checked. Path parts are compared
whole, so a folder like MyPackages isn't mistaken for Packages.

--]]

local EXCLUDED_FOLDERS = { "DevPackages", "node_modules", "Packages", "ServerPackages", "Submodules" }
local EXCLUDED_ROOT_FOLDERS = { ".worktrees", ".wt", "Build" }

local function isExcludedPath(relativePath: string): boolean
    assert(typeof(relativePath) == "string", "Expected a string.")

    local path = string.gsub(string.gsub(relativePath, "\\", "/"), "^%./", "")
    local index = 0
    for part in string.gmatch(path, "[^/]+") do
        index += 1
        if table.find(EXCLUDED_FOLDERS, part) then
            return true
        end
        if index == 1 and table.find(EXCLUDED_ROOT_FOLDERS, part) then
            return true
        end
    end
    return false
end

return isExcludedPath
