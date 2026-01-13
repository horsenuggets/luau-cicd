--[[

CheckChangelogVersionTest

Tests for the CheckChangelogVersion script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

local dedent = TestEnvironment.dedent

return function()
    describe("CheckChangelogVersion", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should pass when changelog has entry for current version", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "CHANGELOG.md",
                dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Initial release
                ]])
            )

            local result = env.runScript("CheckChangelogVersion")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "contains valid entry")).to.be.ok()
        end)

        it("should fail when VERSION file is missing", function()
            env.writeFile(
                "CHANGELOG.md",
                dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Something
                ]])
            )

            local result = env.runScript("CheckChangelogVersion")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "VERSION file not found")).to.be.ok()
        end)

        it("should fail when CHANGELOG.md is missing", function()
            env.writeFile("VERSION", "1.0.0\n")

            local result = env.runScript("CheckChangelogVersion")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "CHANGELOG.md not found")).to.be.ok()
        end)

        it("should fail when version entry is missing from changelog", function()
            env.writeFile("VERSION", "2.0.0\n")
            env.writeFile(
                "CHANGELOG.md",
                dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Initial release
                ]])
            )

            local result = env.runScript("CheckChangelogVersion")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "does not contain an entry")).to.be.ok()
        end)

        it("should fail when version entry is empty", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.writeFile(
                "CHANGELOG.md",
                dedent([[
                    # Changelog

                    ## 1.0.0

                    ## 0.9.0

                    ### Added

                    - Something
                ]])
            )

            local result = env.runScript("CheckChangelogVersion")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "is empty")).to.be.ok()
        end)

        it("should handle multiple versions in changelog", function()
            env.writeFile("VERSION", "2.0.0\n")
            env.writeFile(
                "CHANGELOG.md",
                dedent([[
                    # Changelog

                    ## 2.0.0

                    ### Changed

                    - Major update

                    ## 1.0.0

                    ### Added

                    - Initial release
                ]])
            )

            local result = env.runScript("CheckChangelogVersion")

            expect(result.ok).to.equal(true)
        end)
    end)
end
