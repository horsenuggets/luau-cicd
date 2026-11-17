--[[

CheckChangelogVersionTest.spec

Tests for the CheckChangelogVersion script.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

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

    it("should reject version headings embedded in prose or longer versions", function()
        env.WriteFile("VERSION", "1.0.0\n")
        for _, content in
            {
                "# Changelog\n\n## 0.9.0\n\n- Example ## 1.0.0\n- Older note.\n",
                "# Changelog\n\n## 1.0.00\n\n- Different version.\n",
                "# Changelog\n\n## 1.0.0-beta.1\n\n- Prerelease.\n",
            }
        do
            env.WriteFile("CHANGELOG.md", content)
            const result = env.RunScript("CheckChangelogVersion")
            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "does not contain an entry", 1, true)).to.be.ok()
        end
    end)

    it("should accept complete prerelease and metadata headings with either line ending", function()
        for _, version in { "1.0.0-beta.1", "1.0.0+build.1" } do
            env.WriteFile("VERSION", `{version}\n`)
            for _, newline in { "\n", "\r\n" } do
                env.WriteFile(
                    "CHANGELOG.md",
                    `# Changelog{newline}{newline}## {version}{newline}{newline}- Release note.{newline}`
                )
                const result = env.RunScript("CheckChangelogVersion")
                expect(result.ok).to.equal(true)
            end
        end
    end)

    it("should distinguish empty and populated final sections without a trailing newline", function()
        env.WriteFile("VERSION", "1.0.0\n")
        for _, newline in { "\n", "\r\n" } do
            env.WriteFile("CHANGELOG.md", `# Changelog{newline}{newline}## 1.0.0`)
            const emptyResult = env.RunScript("CheckChangelogVersion")
            expect(emptyResult.ok).to.equal(false)
            expect(string.find(emptyResult.stdout, "is empty", 1, true)).to.be.ok()

            env.WriteFile("CHANGELOG.md", `# Changelog{newline}{newline}## 1.0.0{newline}{newline}- Release note.`)
            const populatedResult = env.RunScript("CheckChangelogVersion")
            expect(populatedResult.ok).to.equal(true)
        end
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
