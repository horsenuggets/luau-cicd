--[[

CheckRokitFormatTest.spec

Tests for the CheckRokitFormat script.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

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
                    styluau = "owner/styluau@2.6.0"
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

    it("should validate tool coordinates independently of TOML quoting", function()
        for _, section in { "[tools]", '["tools"]', "['tools']" } do
            for _, key in { "lune", '"lune"', "'lune'" } do
                for _, quote in { '"', "'" } do
                    for _, coordinate in { "owner/lune@1.0.0-horse.1.2", "Owner/lune@1.0.0-horse.1.2" } do
                        env.WriteFile("test-rokit.toml", `{section}\n{key} = {quote}{coordinate}{quote}\n`)
                        const result = env.RunScript("CheckRokitFormat", { "test-rokit.toml" })
                        expect(result.ok).to.equal(coordinate == string.lower(coordinate))
                        if not result.ok then
                            expect(string.find(result.stdout, 'Tool "lune"', 1, true)).to.be.ok()
                        end
                    end
                end
            end
        end
    end)

    it("should ignore commented tools and unrelated fields", function()
        env.WriteFile(
            "test-rokit.toml",
            "# lune = 'Owner/lune@1.0.0'\n[metadata]\nlune = 'Owner/lune@1.0.0'\nnotes = '''\n[tools]\nlune = \"Owner/lune@1.0.0\"\n'''\n"
        )
        const result = env.RunScript("CheckRokitFormat", { "test-rokit.toml" })
        expect(result.ok).to.equal(true)
    end)

    it("should reject malformed TOML and invalid tool value types", function()
        for _, case in
            {
                { Content = "[tools\n", Message = 'Failed to parse "test-rokit.toml" as TOML' },
                { Content = 'tools = "invalid"\n', Message = 'Expected "tools" to be a table' },
                { Content = "[tools]\nlune = 123\n", Message = 'Expected tool "lune" to be a string' },
                { Content = "[tools]\nlune = true\n", Message = 'Expected tool "lune" to be a string' },
                { Content = "[tools.lune]\n", Message = 'Expected tool "lune" to be a string' }
            }
        do
            env.WriteFile("test-rokit.toml", case.Content)
            const result = env.RunScript("CheckRokitFormat", { "test-rokit.toml" })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, case.Message, 1, true)).to.be.ok()
        end
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
