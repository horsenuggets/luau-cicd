--[[

ExtractChangelogTest.spec

Tests for the ExtractChangelog helper function.

--]]

const Testable = require("@devpackages/Testable")
const afterAll, beforeAll, expect, it = Testable.afterAll, Testable.beforeAll, Testable.expect, Testable.it

const fs = require("@lune/fs")

const ExtractChangelog = require("../Scripts/Helpers/ExtractChangelog.func")
const TestEnvironment = require("./Helpers/TestEnvironment")

const dedent = TestEnvironment.dedent

return function()
    local env: TestEnvironment.Environment
    local tempDir: string

    beforeAll(function()
        env = TestEnvironment.create()
        tempDir = env.Path
    end)

    afterAll(function()
        env.Cleanup()
    end)

    it("should reject a non-string version", function()
        const ok = pcall(function()
            ExtractChangelog(123 :: any, `{tempDir}/CHANGELOG.md`)
        end)
        expect(ok).to.equal(false)
    end)

    it("should reject a non-string changelog path", function()
        const ok = pcall(function()
            ExtractChangelog("1.0.0", 123 :: any)
        end)
        expect(ok).to.equal(false)
    end)

    it("should accept an omitted changelog path", function()
        const ok = pcall(function()
            ExtractChangelog("1.0.0")
        end)
        expect(ok).to.equal(true)
    end)

    it("should extract changelog section for existing version", function()
        const changelogPath = `{tempDir}/CHANGELOG.md`
        fs.writeFile(
            changelogPath,
            dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Feature one
                    - Feature two

                    ## 0.9.0

                    ### Fixed

                    - Bug fix
                ]])
        )

        const section = ExtractChangelog("1.0.0", changelogPath)
        expect(section).to.be.ok()
        expect(string.find(section :: string, "Feature one")).to.be.ok()
        expect(string.find(section :: string, "Feature two")).to.be.ok()
    end)

    it("should extract complete hyphenated version headings literally", function()
        const changelogPath = `{tempDir}/LiteralVersions.md`
        for _, version in { "1.0.0-beta.5", "1.0.0-horse.1.2", "1.0.0-beta.5+build.1" } do
            fs.writeFile(
                changelogPath,
                `# Changelog\n\n## {version}\n\n- Exact version.\n\n## 0.9.0\n\n- Older version.\n`
            )
            expect(ExtractChangelog(version, changelogPath)).to.equal("- Exact version.")
        end
        fs.writeFile(changelogPath, "## 1.0.0-beta.5\n\n- First-line heading.\n")
        expect(ExtractChangelog("1.0.0-beta.5", changelogPath)).to.equal("- First-line heading.")
    end)

    it("should preserve CRLF changelog sections when matching complete headings", function()
        const changelogPath = `{tempDir}/WindowsChangelog.md`
        for _, version in { "1.0.0", "1.0.0-beta.5", "1.0.0-horse.1.2" } do
            fs.writeFile(
                changelogPath,
                `# Changelog\r\n\r\n## {version}\r\n\r\n- First note.\r\n- Second note.\r\n\r\n## 0.9.0\r\n\r\n- Older note.\r\n`
            )
            expect(ExtractChangelog(version, changelogPath)).to.equal("- First note.\r\n- Second note.")
        end
        fs.writeFile(changelogPath, "## 1.0.0-beta.50\r\n\r\n- Wrong version.\r\n")
        expect(ExtractChangelog("1.0.0-beta.5", changelogPath)).to.equal(nil)
    end)

    it("should not match partial or embedded version headings", function()
        const changelogPath = `{tempDir}/UnrelatedHeadings.md`
        for _, heading in { "## 1.0.0-beta.50", "## 1.0.0-beta.5-extra", "Text ## 1.0.0-beta.5", "### 1.0.0-beta.5" } do
            fs.writeFile(changelogPath, `# Changelog\n\n{heading}\n\n- Unrelated content.\n`)
            expect(ExtractChangelog("1.0.0-beta.5", changelogPath)).to.equal(nil)
        end
    end)

    it("should return nil for non-existent version", function()
        const changelogPath = `{tempDir}/CHANGELOG2.md`
        fs.writeFile(
            changelogPath,
            dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Something
                ]])
        )

        const section = ExtractChangelog("2.0.0", changelogPath)
        expect(section).to.equal(nil)
    end)

    it("should extract last version in changelog", function()
        const changelogPath = `{tempDir}/CHANGELOG3.md`
        fs.writeFile(
            changelogPath,
            dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Last version content
                ]])
        )

        const section = ExtractChangelog("1.0.0", changelogPath)
        expect(section).to.be.ok()
        expect(string.find(section :: string, "Last version content")).to.be.ok()
    end)
end
