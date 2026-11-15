--[[

CheckChangelogVersionTest.spec

Tests for the CheckChangelogVersion script.

--]]

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

    it("should pass when changelog has entry for current version", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.WriteFile(
            "CHANGELOG.md",
            dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Initial release
                ]])
        )

        const result = env.RunScript("CheckChangelogVersion")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, '"CHANGELOG.md" contains a valid entry for version "1.0.0".', 1, true)).to.be.ok()
    end)

    it("should fail when VERSION file is missing", function()
        env.WriteFile(
            "CHANGELOG.md",
            dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Something
                ]])
        )

        const result = env.RunScript("CheckChangelogVersion")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, 'The "VERSION" file was not found.', 1, true)).to.be.ok()
    end)

    it("should fail when CHANGELOG.md is missing", function()
        env.WriteFile("VERSION", "1.0.0\n")

        const result = env.RunScript("CheckChangelogVersion")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, '"CHANGELOG.md" was not found.', 1, true)).to.be.ok()
    end)

    it("should fail when version entry is missing from changelog", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile(
            "CHANGELOG.md",
            dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Initial release
                ]])
        )

        const result = env.RunScript("CheckChangelogVersion")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "does not contain an entry")).to.be.ok()
    end)

    it("should fail when version entry is empty", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.WriteFile(
            "CHANGELOG.md",
            dedent([[
                    # Changelog

                    ## 1.0.0

                    ## 0.9.0

                    ### Added

                    - Something
                ]])
        )

        const result = env.RunScript("CheckChangelogVersion")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "is empty")).to.be.ok()
    end)

    it("should handle multiple versions in changelog", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile(
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

        const result = env.RunScript("CheckChangelogVersion")

        expect(result.ok).to.equal(true)
    end)
end
