--[[

BumpVersionTest

Tests for the BumpVersion script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    describe("BumpVersion", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        -- Note: BumpVersion calls SyncVersion via subprocess which may fail in test environment
        -- due to rokit/lune path issues. We verify VERSION file is updated correctly.

        it("should bump patch version", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.0.0"
]]
            )

            local result = env.runScript("BumpVersion", { "patch" })

            -- VERSION should be updated even if sync subprocess fails
            local version = env.readFile("VERSION")
            expect(string.match(version, "^%s*(.-)%s*$")).to.equal("1.0.1")
            expect(string.find(result.stdout, 'Bumping to "1.0.1"')).to.be.ok()
        end)

        it("should bump minor version and reset patch", function()
            env.writeFile("VERSION", "1.2.3\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.2.3"
]]
            )

            local result = env.runScript("BumpVersion", { "minor" })

            local version = env.readFile("VERSION")
            expect(string.match(version, "^%s*(.-)%s*$")).to.equal("1.3.0")
            expect(string.find(result.stdout, 'Bumping to "1.3.0"')).to.be.ok()
        end)

        it("should bump major version and reset minor and patch", function()
            env.writeFile("VERSION", "1.2.3\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.2.3"
]]
            )

            local result = env.runScript("BumpVersion", { "major" })

            local version = env.readFile("VERSION")
            expect(string.match(version, "^%s*(.-)%s*$")).to.equal("2.0.0")
            expect(string.find(result.stdout, 'Bumping to "2.0.0"')).to.be.ok()
        end)

        it("should fail with no arguments", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.0.0"
]]
            )

            local result = env.runScript("BumpVersion", {})

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "[Usage]")).to.be.ok()
        end)

        it("should fail with invalid bump type", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.0.0"
]]
            )

            local result = env.runScript("BumpVersion", { "invalid" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Invalid bump type")).to.be.ok()
        end)

        it("should handle case-insensitive bump type", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.0.0"
]]
            )

            local result = env.runScript("BumpVersion", { "PATCH" })

            local version = env.readFile("VERSION")
            expect(string.match(version, "^%s*(.-)%s*$")).to.equal("1.0.1")
            expect(string.find(result.stdout, 'Bumping to "1.0.1"')).to.be.ok()
        end)

        it("should fail with invalid VERSION format", function()
            env.writeFile("VERSION", "not-a-version\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.0.0"
]]
            )

            local result = env.runScript("BumpVersion", { "patch" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Could not parse")).to.be.ok()
        end)
    end)
end
