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
            expect(isExcludedPath(path)).to.equal(true)
        end
    end)

    it("should skip build output and worktrees only at the root", function()
        expect(isExcludedPath("Build/TestTemp/a.func.luau")).to.equal(true)
        expect(isExcludedPath(".wt/feature/x/Source/a.luau")).to.equal(true)
        expect(isExcludedPath(".worktrees/x/a.luau")).to.equal(true)
        expect(isExcludedPath("Source/Commands/Build/init.luau")).to.equal(false)
        expect(isExcludedPath("Source/.wt/a.luau")).to.equal(false)
    end)

    it("should compare whole path parts", function()
        expect(isExcludedPath("Source/MyPackages/a.luau")).to.equal(false)
        expect(isExcludedPath("Source/BuildTools/a.luau")).to.equal(false)
        expect(isExcludedPath("Builder/a.luau")).to.equal(false)
    end)

    it("should accept leading ./ and Windows separators", function()
        expect(isExcludedPath("./Build/a.json")).to.equal(true)
        expect(isExcludedPath("Build\\a.luau")).to.equal(true)
        expect(isExcludedPath("./Source/a.json")).to.equal(false)
    end)

    it("should keep ordinary source files", function()
        for _, path in { "Source/Module.luau", "Scripts/RunTests.exec.luau", "init.luau", "" } do
            expect(isExcludedPath(path)).to.equal(false)
        end
    end)
end
