--[[

CheckRokitFormatTest.spec

Tests for the CheckRokitFormat script.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

const dedent = TestEnvironment.dedent

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should pass when all tool values are lowercase", function()
        env.WriteFile(
            "test-rokit.toml",
            dedent([[
                    [tools]
                    luau-lsp = "owner/luau-lsp@1.60.0"
                    lune = "owner/lune@0.10.5"
                    stylua = "owner/stylua@2.3.1"
                ]])
        )

        const result = env.RunScript("CheckRokitFormat", { "test-rokit.toml" })

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, '"test-rokit.toml" format is valid.', 1, true)).to.be.ok()
    end)

    it("should fail when a tool value has uppercase letters", function()
        env.WriteFile(
            "test-rokit.toml",
            dedent([[
                    [tools]
                    luau-lsp = "Owner/luau-lsp@1.60.0"
                ]])
        )

        const result = env.RunScript("CheckRokitFormat", { "test-rokit.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
        expect(string.find(result.stdout, "Owner")).to.be.ok()
    end)

    it("should fail when multiple tool values have uppercase letters", function()
        env.WriteFile(
            "test-rokit.toml",
            dedent([[
                    [tools]
                    luau-lsp = "Owner/luau-lsp@1.60.0"
                    lune = "Owner/lune@0.10.5"
                ]])
        )

        const result = env.RunScript("CheckRokitFormat", { "test-rokit.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "2 format error")).to.be.ok()
    end)

    it("should fail when file does not exist", function()
        const result = env.RunScript("CheckRokitFormat", { "nonexistent.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, '"nonexistent.toml" was not found.', 1, true)).to.be.ok()
    end)

    it("should handle empty tools section", function()
        env.WriteFile(
            "test-rokit.toml",
            dedent([[
                    [tools]
                ]])
        )

        const result = env.RunScript("CheckRokitFormat", { "test-rokit.toml" })

        expect(result.ok).to.equal(true)
    end)

    it("should handle values with version numbers containing uppercase", function()
        env.WriteFile(
            "test-rokit.toml",
            dedent([[
                    [tools]
                    some-tool = "owner/repo@1.0.0-BETA"
                ]])
        )

        const result = env.RunScript("CheckRokitFormat", { "test-rokit.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
    end)
end
