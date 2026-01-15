--[[

CheckWallyFormatTest

Tests for the CheckWallyFormat script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

local dedent = TestEnvironment.dedent

return function()
    describe("CheckWallyFormat", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should pass when all repository strings are lowercase", function()
            env.writeFile(
                "test-wally.toml",
                dedent([[
                    [package]
                    name = "horsenuggets/my-package"
                    version = "1.0.0"

                    [dependencies]
                    some-dep = "owner/package@1.0.0"

                    [dev-dependencies]
                    testable = "horsenuggets/testable@0.0.5"
                ]])
            )

            local result = env.runScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "test%-wally%.toml format is valid")).to.be.ok()
        end)

        it("should fail when package name has uppercase letters", function()
            env.writeFile(
                "test-wally.toml",
                dedent([[
                    [package]
                    name = "HorseNuggets/my-package"
                    version = "1.0.0"
                ]])
            )

            local result = env.runScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Package name")).to.be.ok()
            expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
        end)

        it("should fail when dependency has uppercase letters", function()
            env.writeFile(
                "test-wally.toml",
                dedent([[
                    [package]
                    name = "owner/package"
                    version = "1.0.0"

                    [dependencies]
                    some-dep = "Owner/Package@1.0.0"
                ]])
            )

            local result = env.runScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, 'Dependency "some%-dep"')).to.be.ok()
            expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
        end)

        it("should fail when dev-dependency has uppercase letters", function()
            env.writeFile(
                "test-wally.toml",
                dedent([[
                    [package]
                    name = "owner/package"
                    version = "1.0.0"

                    [dev-dependencies]
                    testable = "HorseNuggets/Testable@0.0.5"
                ]])
            )

            local result = env.runScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, 'Dependency "testable"')).to.be.ok()
            expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
        end)

        it("should fail when multiple values have uppercase letters", function()
            env.writeFile(
                "test-wally.toml",
                dedent([[
                    [package]
                    name = "HorseNuggets/my-package"
                    version = "1.0.0"

                    [dependencies]
                    dep-one = "Owner/Package@1.0.0"

                    [dev-dependencies]
                    testable = "HorseNuggets/Testable@0.0.5"
                ]])
            )

            local result = env.runScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "3 format error")).to.be.ok()
        end)

        it("should fail when file does not exist", function()
            local result = env.runScript("CheckWallyFormat", { "nonexistent.toml" })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "nonexistent%.toml not found")).to.be.ok()
        end)

        it("should pass when no dependencies section exists", function()
            env.writeFile(
                "test-wally.toml",
                dedent([[
                    [package]
                    name = "owner/package"
                    version = "1.0.0"
                ]])
            )

            local result = env.runScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(true)
        end)

        it("should not check other string fields like description", function()
            env.writeFile(
                "test-wally.toml",
                dedent([[
                    [package]
                    name = "owner/package"
                    description = "This Has Uppercase Letters"
                    version = "1.0.0"
                ]])
            )

            local result = env.runScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(true)
        end)

        it("should not check URL fields like registry and repository", function()
            env.writeFile(
                "test-wally.toml",
                dedent([[
                    [package]
                    name = "owner/package"
                    version = "1.0.0"
                    registry = "https://github.com/UpliftGames/wally-index"
                    repository = "https://github.com/HorseNuggets/Package"
                ]])
            )

            local result = env.runScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(true)
        end)
    end)
end
