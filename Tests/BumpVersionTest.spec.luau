--[[

BumpVersionTest.spec

Tests for the BumpVersion script.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

const dedent = TestEnvironment.dedent

return function()
    describe("BumpVersion", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should bump patch version", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
            )

            const result = env.runScript("BumpVersion", { "patch" })

            const version = env.readFile("VERSION")
            expect(string.match(version, "^%s*(.-)%s*$")).to.equal("1.0.1")
            expect(string.find(result.stdout, 'Bumping to "1.0.1"')).to.be.ok()
        end)

        it("should sync wally.toml when run from outside the luau-cicd folder", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
            )

            -- The test environment runs scripts with a temp folder as the working directory,
            -- the same way a consumer repo runs them through Submodules/luau-cicd/
            const result = env.runScript("BumpVersion", { "patch" })

            expect(result.ok).to.equal(true)
            expect(string.find(env.readFile("wally.toml"), 'version = "1.0.1"', 1, true)).to.be.ok()
        end)

        it("should bump minor version and reset patch", function()
            env.writeFile("VERSION", "1.2.3\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.2.3"
                ]])
            )

            const result = env.runScript("BumpVersion", { "minor" })

            const version = env.readFile("VERSION")
            expect(string.match(version, "^%s*(.-)%s*$")).to.equal("1.3.0")
            expect(string.find(result.stdout, 'Bumping to "1.3.0"')).to.be.ok()
        end)

        it("should bump major version and reset minor and patch", function()
            env.writeFile("VERSION", "1.2.3\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.2.3"
                ]])
            )

            const result = env.runScript("BumpVersion", { "major" })

            const version = env.readFile("VERSION")
            expect(string.match(version, "^%s*(.-)%s*$")).to.equal("2.0.0")
            expect(string.find(result.stdout, 'Bumping to "2.0.0"')).to.be.ok()
        end)

        it("should fail with no arguments", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
            )

            const result = env.runScript("BumpVersion", {})

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "[Usage]")).to.be.ok()
        end)

        it("should fail with invalid bump type", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
            )

            const result = env.runScript("BumpVersion", { "invalid" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Invalid bump type")).to.be.ok()
        end)

        it("should handle case-insensitive bump type", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
            )

            const result = env.runScript("BumpVersion", { "PATCH" })

            const version = env.readFile("VERSION")
            expect(string.match(version, "^%s*(.-)%s*$")).to.equal("1.0.1")
            expect(string.find(result.stdout, 'Bumping to "1.0.1"')).to.be.ok()
        end)

        it("should fail with invalid VERSION format", function()
            env.writeFile("VERSION", "not-a-version\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
            )

            const result = env.runScript("BumpVersion", { "patch" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Could not parse")).to.be.ok()
        end)
    end)
end
