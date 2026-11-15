--[[

CheckLuaurcFormatTest.spec

Tests for the CheckLuaurcFormat script.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    describe("self alias validation", function()
        it("should pass when no self alias is present", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "devpackages": "DevPackages/"
    }
}]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "format is valid")).to.be.ok()
        end)

        it("should fail when self alias is present", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "self": "Source/",
        "devpackages": "DevPackages/"
    }
}]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "@self is built%-in")).to.be.ok()
        end)

        it("should fail when @self alias is present", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "@self": "Source/",
        "devpackages": "DevPackages/"
    }
}]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "@self is built%-in")).to.be.ok()
        end)

        it("should fail when Self alias is present (case insensitive)", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "Self": "Source/"
    }
}]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "@self is built%-in")).to.be.ok()
        end)
    end)

    describe("lune version validation", function()
        it("should pass when lune alias matches rokit.toml version", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "lune": "~/.lune/.typedefs/0.10.5/",
        "devpackages": "DevPackages/"
    }
}]=]
            )
            env.WriteFile(
                "test-rokit.toml",
                [=[
[tools]
lune = "owner/lune@0.10.5"
stylua = "owner/stylua@2.3.1"
]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

            expect(result.ok).to.equal(true)
        end)

        it("should fail when lune alias version does not match rokit.toml", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "lune": "~/.lune/.typedefs/0.9.0/",
        "devpackages": "DevPackages/"
    }
}]=]
            )
            env.WriteFile(
                "test-rokit.toml",
                [=[
[tools]
lune = "owner/lune@0.10.5"
]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "does not match rokit.toml version")).to.be.ok()
            expect(string.find(result.stdout, "0.10.5")).to.be.ok()
        end)

        it("should fail when lune is in rokit.toml but no alias in luaurc", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "devpackages": "DevPackages/"
    }
}]=]
            )
            env.WriteFile(
                "test-rokit.toml",
                [=[
[tools]
lune = "owner/lune@0.10.5"
]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, '"test.luaurc" has no lune alias.', 1, true)).to.be.ok()
        end)

        it("should pass when no lune in rokit.toml and no lune alias", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "devpackages": "DevPackages/"
    }
}]=]
            )
            env.WriteFile(
                "test-rokit.toml",
                [=[
[tools]
stylua = "owner/stylua@2.3.1"
]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

            expect(result.ok).to.equal(true)
        end)

        it("should ignore comments, similarly named tools, and lune outside tools", function()
            env.WriteFile("test.luaurc", "{}\n")
            for _, rokit in
                {
                    '# lune = "owner/lune@0.10.5"\n[tools]\nstylua = "owner/stylua@2.3.1"\n',
                    '[tools]\nother-lune = "owner/lune@0.10.5"\n',
                    'lune = "owner/lune@0.10.5"\n',
                    '[metadata]\nlune = "owner/lune@0.10.5"\n',
                    "",
                }
            do
                env.WriteFile("test-rokit.toml", rokit)
                const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })
                expect(result.ok).to.equal(true)
            end
        end)

        it("should read the actual lune tool rather than commented coordinates", function()
            env.WriteFile("test.luaurc", '{"aliases":{"lune":"~/.lune/.typedefs/0.10.5/"}}\n')
            env.WriteFile("test-rokit.toml", '# lune = "owner/lune@0.9.0"\n[tools]\n"lune" = \'owner/lune@0.10.5\'\n')

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

            expect(result.ok).to.equal(true)
        end)

        it("should reject invalid Rokit tools and lune value types clearly", function()
            env.WriteFile("test.luaurc", "{}\n")
            for _, case in
                {
                    { Content = 'tools = "invalid"\n', Message = 'Expected "tools" to be a table' },
                    { Content = "[tools]\nlune = true\n", Message = 'Expected "tools.lune" to be a string' },
                    { Content = "[tools]\nlune = 123\n", Message = 'Expected "tools.lune" to be a string' },
                    { Content = "[tools.lune]\n", Message = 'Expected "tools.lune" to be a string' },
                    {
                        Content = '[tools]\nlune = "owner/lune"\n',
                        Message = 'Expected "tools.lune" to include a version',
                    },
                    { Content = "[tools\n", Message = 'Failed to parse "test-rokit.toml" as TOML' },
                }
            do
                env.WriteFile("test-rokit.toml", case.Content)
                const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })
                expect(result.ok).to.equal(false)
                expect(string.find(result.stderr, case.Message, 1, true)).to.be.ok()
            end
        end)

        it("should pass when rokit.toml does not exist", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {
        "devpackages": "DevPackages/"
    }
}]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

            expect(result.ok).to.equal(true)
        end)
    end)

    describe("general validation", function()
        it("should pass when aliases section is empty", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "aliases": {}
}]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

            expect(result.ok).to.equal(true)
        end)

        it("should pass when no aliases section exists", function()
            env.WriteFile(
                "test.luaurc",
                [=[{
    "globals": ["describe", "it", "expect"]
}]=]
            )

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

            expect(result.ok).to.equal(true)
        end)

        it("should fail when file does not exist", function()
            const result = env.RunScript("CheckLuaurcFormat", { "nonexistent.luaurc" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "not found")).to.be.ok()
        end)

        it("should fail when file is not valid JSON", function()
            env.WriteFile("test.luaurc", "this is not json")

            const result = env.RunScript("CheckLuaurcFormat", { "test.luaurc" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Failed to parse")).to.be.ok()
        end)
    end)
end
