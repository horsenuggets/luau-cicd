--[[

LintTest.spec

Tests lint configuration validation and analysis result classification without launching
external analysis tools.

--]]

const Testable = require("@devpackages/Testable")
const expect, it = Testable.expect, Testable.it

const HasAnalysisIssues = require("../Scripts/Helpers/HasAnalysisIssues.func")
const Lint = require("../Scripts/Helpers/Lint")

return function()
    it("should reject failed processes and diagnostics on either stream", function()
        const diagnostic = "Source/Module.luau(1,1): LocalUnused: Variable is never used."
        const information = "[INFO] Loading built-in definitions from the Lune platform.\n"

        for _, ok in { false, true } do
            for _, stdoutHasIssue in { false, true } do
                for _, stderrHasIssue in { false, true } do
                    const stdout = if stdoutHasIssue then diagnostic else information
                    const stderr = if stderrHasIssue then diagnostic else information
                    const expected = not ok or stdoutHasIssue or stderrHasIssue

                    expect(HasAnalysisIssues(ok, stdout, stderr)).to.equal(expected)
                    expect(HasAnalysisIssues(ok, stdout, stderr)).to.equal(expected)
                end
            end
        end
    end)

    it("should accept successful analysis with empty output", function()
        expect(HasAnalysisIssues(true, "", "")).to.equal(false)
    end)

    it("should recognize errors and deprecation warnings on either stream", function()
        for _, diagnostic in
            {
                "Source/Module.luau(2,3): TypeError: Unknown type.",
                "Source/Module.luau(4,5): DeprecatedApi: Function is deprecated."
            }
        do
            expect(HasAnalysisIssues(true, diagnostic, "")).to.equal(true)
            expect(HasAnalysisIssues(true, "", diagnostic)).to.equal(true)
        end
    end)

    it("should validate analysis result parameters", function()
        for _, call in
            {
                function()
                    HasAnalysisIssues(1 :: any, "", "")
                end,
                function()
                    HasAnalysisIssues(true, false :: any, "")
                end,
                function()
                    HasAnalysisIssues(true, "", false :: any)
                end
            }
        do
            const ok = pcall(call)
            expect(ok).to.equal(false)
        end
    end)

    it("should accept an empty platform list and optional ignore patterns", function()
        for _, config in
            {
                { Platforms = {} },
                { IgnorePatterns = {}, Platforms = {} },
                { IgnorePatterns = { "Generated/**" }, Platforms = {} }
            }
        do
            const ok = pcall(function()
                Lint.run(config)
            end)
            expect(ok).to.equal(true)
        end
    end)

    it("should reject invalid top-level configuration fields", function()
        for _, config in
            {
                false,
                { IgnorePatterns = false, Platforms = {} },
                { IgnorePatterns = { false }, Platforms = {} },
                { Platforms = false },
                { Platforms = { false } }
            }
        do
            const ok = pcall(function()
                Lint.run(config :: any)
            end)
            expect(ok).to.equal(false)
        end
    end)

    it("should reject invalid platform fields before running analysis", function()
        for _, entry in
            {
                {},
                { Platform = false, Targets = {} },
                { Platform = "lune", Targets = false },
                { Platform = "lune", Targets = { false } },
                { IgnorePatterns = false, Platform = "lune", Targets = {} },
                { IgnorePatterns = { false }, Platform = "lune", Targets = {} },
                { Platform = "lune", RojoProject = false, Targets = {} },
                { Platform = "lune", Sourcemap = false, Targets = {} }
            }
        do
            const ok = pcall(function()
                Lint.run({ Platforms = { entry } } :: any)
            end)
            expect(ok).to.equal(false)
        end
    end)
end
