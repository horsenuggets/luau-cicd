--[[

CheckChangelogFormatTest.spec

Tests for the CheckChangelogFormat script.

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

    describe("valid changelogs", function()
        it("should pass for a properly formatted changelog with one version", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changelog

                        ## 1.0.0
                        - Initial release
                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "format is valid")).to.be.ok()
        end)

        it("should pass for a changelog with multiple versions", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changelog

                        ## 2.0.0
                        - New feature
                        - Updated behavior

                        ## 1.0.0
                        - Initial release
                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(true)
        end)

        it("should pass for a changelog with multiple items per version", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changelog

                        ## 1.0.0
                        - Added a thing
                        - Changed a thing
                        - Fixed a thing
                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(true)
        end)
    end)

    describe("missing file", function()
        it("should fail when CHANGELOG.md is missing", function()
            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, '"CHANGELOG.md" was not found.', 1, true)).to.be.ok()
        end)
    end)

    describe("header validation", function()
        it("should fail when first line is not # Changelog", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changes

                        ## 1.0.0
                        - Something
                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, 'First line must be exactly "# Changelog"')).to.be.ok()
        end)

        it("should fail when there is no blank line after title", function()
            env.WriteFile("CHANGELOG.md", "# Changelog\n## 1.0.0\n- Something\n")

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Second line must be blank")).to.be.ok()
        end)
    end)

    describe("version section validation", function()
        it("should accept bare versions and hyphenated suffixes", function()
            for _, version in { "1.0.0", "1.0.0-beta", "1.0.0-beta.5", "1.0.0-horse.1.2" } do
                env.WriteFile("CHANGELOG.md", `# Changelog\n\n## {version}\n- A release.\n`)

                const result = env.RunScript("CheckChangelogFormat")

                expect(result.ok).to.equal(true)
            end
        end)

        it("should reject version suffixes without a hyphen or content", function()
            for _, version in { "1.0.0beta", "1.0.0.1", "1.0.0-" } do
                env.WriteFile("CHANGELOG.md", `# Changelog\n\n## {version}\n- A release.\n`)

                const result = env.RunScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "must use a version header", 1, true)).to.be.ok()
            end
        end)

        it("should fail when version format is invalid", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changelog

                        ## v1.0.0
                        - Something
                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(
                string.find(
                    result.stdout,
                    'must use a version header in the "## X.Y.Z" or "## X.Y.Z-suffix" format.',
                    1,
                    true
                )
            ).to.be.ok()
        end)

        it("should fail when changelog has no versions", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changelog

                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "must contain at least one version section")).to.be.ok()
        end)
    end)

    describe("subsection validation", function()
        it("should fail when subsection headers are used", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changelog

                        ## 1.0.0

                        ### Added
                        - Something
                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "has a subsection header.", 1, true)).to.be.ok()
            expect(string.find(result.stdout, "List items must go directly under the version.", 1, true)).to.be.ok()
        end)
    end)

    describe("list item validation", function()
        it("should fail when list item has no space after dash", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changelog

                        ## 1.0.0
                        -Something
                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(
                string.find(
                    result.stdout,
                    'must use a space after the dash, such as "- item" rather than "-item".',
                    1,
                    true
                )
            ).to.be.ok()
        end)

        it("should fail when list item is indented", function()
            env.WriteFile("CHANGELOG.md", "# Changelog\n\n## 1.0.0\n  - Something\n")

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "has an indented list item.", 1, true)).to.be.ok()
        end)

        it("should fail when list item is outside a version section", function()
            env.WriteFile(
                "CHANGELOG.md",
                dedent([[
                        # Changelog

                        - Something without version
                    ]])
            )

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "has a list item outside a version section.", 1, true)).to.be.ok()
        end)
    end)

    describe("newline validation", function()
        it("should fail when file does not end with newline", function()
            env.WriteFile("CHANGELOG.md", "# Changelog\n\n## 1.0.0\n- Something")

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "must end with a newline")).to.be.ok()
        end)

        it("should fail when file ends with multiple newlines", function()
            env.WriteFile("CHANGELOG.md", "# Changelog\n\n## 1.0.0\n- Something\n\n")

            const result = env.RunScript("CheckChangelogFormat")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "exactly one newline")).to.be.ok()
        end)
    end)
end
