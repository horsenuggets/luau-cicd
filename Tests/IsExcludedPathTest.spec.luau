--[[

IsExcludedPathTest.spec

Tests for the isExcludedPath helper that the file scanning checks share.

--]]

local isExcludedPath = require("../Scripts/Helpers/isExcludedPath")

return function()
    it("should skip dependency and submodule folders at any depth", function()
        local paths = {
            "Packages/Fusion.luau",
            "DevPackages/Testable.luau",
            "ServerPackages/x.luau",
            "Submodules/luau-cicd/Scripts/Lint.luau",
            "web/node_modules/a/b.json",
            "Source/Packages/x.luau",
            "Packages/",
        }
        for _, path in paths do
            for _, scanningRepoRoot in { true, false } do
                expect(isExcludedPath(path, scanningRepoRoot)).to.equal(true)
            end
        end
    end)

    it("should skip build output and worktrees at the root of a repo scan", function()
        expect(isExcludedPath("Build/TestTemp/a.func.luau", true)).to.equal(true)
        expect(isExcludedPath(".wt/feature/x/Source/a.luau", true)).to.equal(true)
        expect(isExcludedPath(".worktrees/x/a.luau", true)).to.equal(true)
    end)

    it("should check root-only folders deeper down or in subfolder scans", function()
        expect(isExcludedPath("Source/Commands/Build/init.luau", true)).to.equal(false)
        expect(isExcludedPath("Source/.wt/a.luau", true)).to.equal(false)
        -- Scanning Source/Commands directly makes its Build folder look like a root one
        expect(isExcludedPath("Build/init.luau", false)).to.equal(false)
        expect(isExcludedPath(".wt/a.luau", false)).to.equal(false)
    end)

    it("should compare whole path parts", function()
        expect(isExcludedPath("Source/MyPackages/a.luau", true)).to.equal(false)
        expect(isExcludedPath("Source/BuildTools/a.luau", true)).to.equal(false)
        expect(isExcludedPath("Builder/a.luau", true)).to.equal(false)
    end)

    it("should accept leading ./ and Windows separators", function()
        expect(isExcludedPath("./Build/a.json", true)).to.equal(true)
        expect(isExcludedPath("Build\\a.luau", true)).to.equal(true)
        expect(isExcludedPath("./Source/a.json", true)).to.equal(false)
    end)

    it("should keep ordinary source files", function()
        for _, path in { "Source/Module.luau", "Scripts/RunTests.exec.luau", "init.luau", "" } do
            expect(isExcludedPath(path, true)).to.equal(false)
        end
    end)
end
