--[[

SyncVersionTest

Tests for the SyncVersion script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    describe("SyncVersion", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should update wally.toml version to match VERSION file", function()
            env.writeFile("VERSION", "1.2.3\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "0.0.0"
]]
            )

            local result = env.runScript("SyncVersion")

            expect(result.ok).to.equal(true)
            local wallyContent = env.readFile("wally.toml")
            expect(string.find(wallyContent, 'version = "1.2.3"')).to.be.ok()
        end)

        it("should handle VERSION with trailing whitespace", function()
            env.writeFile("VERSION", "  2.0.0  \n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.0.0"
]]
            )

            local result = env.runScript("SyncVersion")

            expect(result.ok).to.equal(true)
            local wallyContent = env.readFile("wally.toml")
            expect(string.find(wallyContent, 'version = "2.0.0"')).to.be.ok()
        end)

        it("should preserve other wally.toml content", function()
            env.writeFile("VERSION", "3.0.0\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
description = "A test package"
version = "1.0.0"
license = "MIT"

[dependencies]
something = "author/something@1.0.0"
]]
            )

            local result = env.runScript("SyncVersion")

            expect(result.ok).to.equal(true)
            local wallyContent = env.readFile("wally.toml")
            expect(string.find(wallyContent, 'version = "3.0.0"')).to.be.ok()
            expect(string.find(wallyContent, 'name = "test/package"')).to.be.ok()
            expect(string.find(wallyContent, 'description = "A test package"')).to.be.ok()
            expect(string.find(wallyContent, 'license = "MIT"')).to.be.ok()
            expect(string.find(wallyContent, "something")).to.be.ok()
        end)

        it("should only update version in package section", function()
            env.writeFile("VERSION", "5.0.0\n")
            env.writeFile(
                "wally.toml",
                [[
[package]
name = "test/package"
version = "1.0.0"

[dependencies]
dep = "author/dep@2.0.0"
]]
            )

            local result = env.runScript("SyncVersion")

            expect(result.ok).to.equal(true)
            local wallyContent = env.readFile("wally.toml")
            expect(string.find(wallyContent, 'version = "5.0.0"')).to.be.ok()
            -- Dependency version should remain unchanged
            expect(string.find(wallyContent, "dep@2.0.0")).to.be.ok()
        end)
    end)
end
