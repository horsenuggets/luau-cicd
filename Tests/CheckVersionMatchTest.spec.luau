--[[

CheckVersionMatchTest

Tests for the CheckVersionMatch script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

local dedent = TestEnvironment.dedent

return function()
    describe("CheckVersionMatch", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should pass when versions match", function()
            env.writeFile("VERSION", "1.2.3\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.2.3"
                ]])
            )

            local result = env.runScript("CheckVersionMatch")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, 'Versions match "1.2.3"')).to.be.ok()
        end)

        it("should fail when versions do not match", function()
            env.writeFile("VERSION", "2.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
            )

            local result = env.runScript("CheckVersionMatch")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Version mismatch")).to.be.ok()
        end)

        it("should handle VERSION with whitespace", function()
            env.writeFile("VERSION", "  1.0.0  \n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
            )

            local result = env.runScript("CheckVersionMatch")

            expect(result.ok).to.equal(true)
        end)

        it("should fail when wally.toml has no version", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                ]])
            )

            local result = env.runScript("CheckVersionMatch")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Could not find version")).to.be.ok()
        end)

        it("should match versions with different formatting in wally.toml", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version="1.0.0"
                ]])
            )

            local result = env.runScript("CheckVersionMatch")

            expect(result.ok).to.equal(true)
        end)
    end)
end
