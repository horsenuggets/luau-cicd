--[[

IsExcludedPathTest.spec

Tests for the IsExcludedPath helper that the file scanning checks share.

--]]

const Testable = require("@devpackages/Testable")
const expect, it = Testable.expect, Testable.it

const IsExcludedPath = require("../Scripts/Helpers/IsExcludedPath.func")
const process = require("@lune/process")

return function()
    it("should reject a non-string path", function()
        const ok = pcall(function()
            IsExcludedPath(123 :: any, true)
        end)
        expect(ok).to.equal(false)
    end)

    it("should reject a non-boolean root flag", function()
        const ok = pcall(function()
            IsExcludedPath("Source/Module.luau", "true" :: any)
        end)
        expect(ok).to.equal(false)
    end)

    it("should skip dependency and submodule folders at any depth", function()
        const paths = {
            "Packages/Fusion.luau",
            "DevPackages/Testable.luau",
            "ServerPackages/x.luau",
            "Submodules/luau-cicd/Scripts/Lint.exec.luau",
            "web/node_modules/a/b.json",
            "Source/Packages/x.luau",
            "Packages/"
        }
        for _, path in paths do
            for _, scanningRepoRoot in { true, false } do
                expect(IsExcludedPath(path, scanningRepoRoot)).to.equal(true)
            end
        end
    end)

    it("should skip build output and worktrees at the root of a repo scan", function()
        expect(IsExcludedPath("Build/TestTemp/a.func.luau", true)).to.equal(true)
        expect(IsExcludedPath(".wt/feature/x/Source/a.luau", true)).to.equal(true)
        expect(IsExcludedPath(".worktrees/x/a.luau", true)).to.equal(true)
    end)

    it("should check root-only folders deeper down or in subfolder scans", function()
        expect(IsExcludedPath("Source/Commands/Build/init.luau", true)).to.equal(false)
        expect(IsExcludedPath("Source/.wt/a.luau", true)).to.equal(false)
        -- Scanning Source/Commands directly makes its Build folder look like a root one.
        expect(IsExcludedPath("Build/init.luau", false)).to.equal(false)
        expect(IsExcludedPath(".wt/a.luau", false)).to.equal(false)
    end)

    it("should compare whole path parts", function()
        expect(IsExcludedPath("Source/MyPackages/a.luau", true)).to.equal(false)
        expect(IsExcludedPath("Source/BuildTools/a.luau", true)).to.equal(false)
        expect(IsExcludedPath("Builder/a.luau", true)).to.equal(false)
    end)

    it("should accept leading ./ and native separators", function()
        expect(IsExcludedPath("./Build/a.json", true)).to.equal(true)
        expect(IsExcludedPath("./Source/a.json", true)).to.equal(false)
        for _, path in { "Build\\Source/a.luau", "Source\\Packages/a.luau" } do
            expect(IsExcludedPath(path, true)).to.equal(process.os == "windows")
        end
    end)

    it("should keep ordinary source files", function()
        for _, path in { "Source/Module.luau", "Scripts/RunTests.exec.luau", "init.luau", "" } do
            expect(IsExcludedPath(path, true)).to.equal(false)
        end
    end)
end
