--[[

CheckChangelogFormatTest

Tests for the CheckChangelogFormat script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

local dedent = TestEnvironment.dedent

return function()
    describe("CheckChangelogFormat", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        describe("valid changelogs", function()
            it("should pass for a properly formatted changelog with one version", function()
                env.writeFile(
                    "CHANGELOG.md",
                    dedent([[
						# Changelog

						## 1.0.0
						- Initial release
					]])
                )

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(true)
                expect(string.find(result.stdout, "format is valid")).to.be.ok()
            end)

            it("should pass for a changelog with multiple versions", function()
                env.writeFile(
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

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(true)
            end)

            it("should pass for a changelog with multiple items per version", function()
                env.writeFile(
                    "CHANGELOG.md",
                    dedent([[
						# Changelog

						## 1.0.0
						- Added a thing
						- Changed a thing
						- Fixed a thing
					]])
                )

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(true)
            end)
        end)

        describe("missing file", function()
            it("should fail when CHANGELOG.md is missing", function()
                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "CHANGELOG.md not found")).to.be.ok()
            end)
        end)

        describe("header validation", function()
            it("should fail when first line is not # Changelog", function()
                env.writeFile(
                    "CHANGELOG.md",
                    dedent([[
						# Changes

						## 1.0.0
						- Something
					]])
                )

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, 'First line must be exactly "# Changelog"')).to.be.ok()
            end)

            it("should fail when there is no blank line after title", function()
                env.writeFile("CHANGELOG.md", "# Changelog\n## 1.0.0\n- Something\n")

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "Second line must be blank")).to.be.ok()
            end)
        end)

        describe("version section validation", function()
            it("should fail when version format is invalid", function()
                env.writeFile(
                    "CHANGELOG.md",
                    dedent([[
						# Changelog

						## v1.0.0
						- Something
					]])
                )

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, 'Version header must be exactly "## X.Y.Z"')).to.be.ok()
            end)

            it("should fail when changelog has no versions", function()
                env.writeFile(
                    "CHANGELOG.md",
                    dedent([[
						# Changelog

					]])
                )

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "must contain at least one version section")).to.be.ok()
            end)
        end)

        describe("subsection validation", function()
            it("should fail when subsection headers are used", function()
                env.writeFile(
                    "CHANGELOG.md",
                    dedent([[
						# Changelog

						## 1.0.0

						### Added
						- Something
					]])
                )

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "Subsection headers")).to.be.ok()
                expect(string.find(result.stdout, "not allowed")).to.be.ok()
            end)
        end)

        describe("list item validation", function()
            it("should fail when list item has no space after dash", function()
                env.writeFile(
                    "CHANGELOG.md",
                    dedent([[
						# Changelog

						## 1.0.0
						-Something
					]])
                )

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "must have a space after the dash")).to.be.ok()
            end)

            it("should fail when list item is indented", function()
                env.writeFile("CHANGELOG.md", "# Changelog\n\n## 1.0.0\n  - Something\n")

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "must not be indented")).to.be.ok()
            end)

            it("should fail when list item is outside a version section", function()
                env.writeFile(
                    "CHANGELOG.md",
                    dedent([[
						# Changelog

						- Something without version
					]])
                )

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "must be inside a version section")).to.be.ok()
            end)
        end)

        describe("newline validation", function()
            it("should fail when file does not end with newline", function()
                env.writeFile("CHANGELOG.md", "# Changelog\n\n## 1.0.0\n- Something")

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "must end with a newline")).to.be.ok()
            end)

            it("should fail when file ends with multiple newlines", function()
                env.writeFile("CHANGELOG.md", "# Changelog\n\n## 1.0.0\n- Something\n\n")

                local result = env.runScript("CheckChangelogFormat")

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "exactly one newline")).to.be.ok()
            end)
        end)
    end)
end
