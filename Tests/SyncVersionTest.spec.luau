--[[

SyncVersionTest

Tests for the SyncVersion script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

local dedent = TestEnvironment.dedent

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
                dedent([[
                    [package]
                    name = "test/package"
                    version = "0.0.0"
                ]])
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
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
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
                dedent([[
                    [package]
                    name = "test/package"
                    description = "A test package"
                    version = "1.0.0"
                    license = "MIT"

                    [dependencies]
                    something = "author/something@1.0.0"
                ]])
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
                dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"

                    [dependencies]
                    dep = "author/dep@2.0.0"
                ]])
            )

            local result = env.runScript("SyncVersion")

            expect(result.ok).to.equal(true)
            local wallyContent = env.readFile("wally.toml")
            expect(string.find(wallyContent, 'version = "5.0.0"')).to.be.ok()
            -- Dependency version should remain unchanged
            expect(string.find(wallyContent, "dep@2.0.0")).to.be.ok()
        end)

        it("should update README.md version if package dependency string exists", function()
            env.writeFile("VERSION", "2.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "author/my-package"
                    version = "1.0.0"
                ]])
            )
            env.writeFile(
                "README.md",
                dedent([[
                    # my-package

                    ## Installation

                    Add to your wally.toml:

                    ```toml
                    [dependencies]
                    MyPackage = "author/my-package@1.0.0"
                    ```
                ]])
            )

            local result = env.runScript("SyncVersion")

            expect(result.ok).to.equal(true)
            local readmeContent = env.readFile("README.md")
            expect(string.find(readmeContent, "author/my%-package@2%.0%.0")).to.be.ok()
        end)

        it("should update multiple README.md version references", function()
            env.writeFile("VERSION", "3.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "author/my-package"
                    version = "1.0.0"
                ]])
            )
            env.writeFile(
                "README.md",
                dedent([[
                    # my-package

                    Install: `author/my-package@1.0.0`

                    Or add to wally.toml:
                    MyPackage = "author/my-package@1.0.0"
                ]])
            )

            local result = env.runScript("SyncVersion")

            expect(result.ok).to.equal(true)
            local readmeContent = env.readFile("README.md")
            -- Both occurrences should be updated
            local _, count = string.gsub(readmeContent, "author/my%-package@3%.0%.0", "")
            expect(count).to.equal(2)
        end)

        it("should not modify README.md if no package dependency string exists", function()
            env.writeFile("VERSION", "2.0.0\n")
            env.writeFile(
                "wally.toml",
                dedent([[
                    [package]
                    name = "author/my-package"
                    version = "1.0.0"
                ]])
            )
            env.writeFile(
                "README.md",
                dedent([[
                    # my-package

                    This is a package without installation instructions.
                ]])
            )

            local result = env.runScript("SyncVersion")

            expect(result.ok).to.equal(true)
            local readmeContent = env.readFile("README.md")
            expect(string.find(readmeContent, "without installation")).to.be.ok()
        end)
    end)
end
