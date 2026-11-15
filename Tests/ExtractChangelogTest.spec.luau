--[[

ExtractChangelogTest.spec

Tests for the ExtractChangelog helper function.

--]]

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
