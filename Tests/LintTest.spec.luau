--[[

LintTest.spec

Tests lint configuration validation without launching external analysis tools.

--]]

const Lint = require("../Scripts/Helpers/Lint")

return function()
    it("should accept an empty platform list and optional ignore patterns", function()
        for _, config in
            {
                { Platforms = {} },
                { IgnorePatterns = {}, Platforms = {} },
                { IgnorePatterns = { "Generated/**" }, Platforms = {} },
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
                { Platforms = { false } },
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
                { Platform = "lune", Sourcemap = false, Targets = {} },
            }
        do
            const ok = pcall(function()
                Lint.run({ Platforms = { entry } } :: any)
            end)
            expect(ok).to.equal(false)
        end
    end)
end
