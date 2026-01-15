--[[

CheckRokitFormatTest

Tests for the CheckRokitFormat script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

local dedent = TestEnvironment.dedent

return function()
    describe("CheckRokitFormat", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should pass when all tool values are lowercase", function()
            env.writeFile(
                "test-rokit.toml",
                dedent([[
                    [tools]
                    luau-lsp = "johnnymorganz/luau-lsp@1.60.0"
                    lune = "horsenuggets/lune@0.10.5"
                    stylua = "johnnymorganz/stylua@2.3.1"
                ]])
            )

            local result = env.runScript("CheckRokitFormat", { "test-rokit.toml" })

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "test%-rokit%.toml format is valid")).to.be.ok()
        end)

        it("should fail when a tool value has uppercase letters", function()
            env.writeFile(
                "test-rokit.toml",
                dedent([[
                    [tools]
                    luau-lsp = "JohnnyMorganz/luau-lsp@1.60.0"
                ]])
            )

            local result = env.runScript("CheckRokitFormat", { "test-rokit.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
            expect(string.find(result.stdout, "JohnnyMorganz")).to.be.ok()
        end)

        it("should fail when multiple tool values have uppercase letters", function()
            env.writeFile(
                "test-rokit.toml",
                dedent([[
                    [tools]
                    luau-lsp = "JohnnyMorganz/luau-lsp@1.60.0"
                    lune = "HorseNuggets/lune@0.10.5"
                ]])
            )

            local result = env.runScript("CheckRokitFormat", { "test-rokit.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "2 format error")).to.be.ok()
        end)

        it("should fail when file does not exist", function()
            local result = env.runScript("CheckRokitFormat", { "nonexistent.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "nonexistent%.toml not found")).to.be.ok()
        end)

        it("should handle empty tools section", function()
            env.writeFile(
                "test-rokit.toml",
                dedent([[
                    [tools]
                ]])
            )

            local result = env.runScript("CheckRokitFormat", { "test-rokit.toml" })

            expect(result.ok).to.equal(true)
        end)

        it("should handle values with version numbers containing uppercase", function()
            env.writeFile(
                "test-rokit.toml",
                dedent([[
                    [tools]
                    some-tool = "owner/repo@1.0.0-BETA"
                ]])
            )

            local result = env.runScript("CheckRokitFormat", { "test-rokit.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
        end)
    end)
end
