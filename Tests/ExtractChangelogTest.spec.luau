--[[

ExtractChangelogTest.spec

Tests for the extractChangelog helper function.

--]]

const fs = require("@lune/fs")
const process = require("@lune/process")

const TestEnvironment = require("./Helpers/TestEnvironment")
const extractChangelog = require("../Scripts/Helpers/extractChangelog")

const dedent = TestEnvironment.dedent

return function()
    describe("extractChangelog", function()
        local tempDir: string

        beforeAll(function()
            -- Create a unique temp directory for this test suite
            const timestamp = tostring(os.time()) .. tostring(math.random(1000, 9999))
            tempDir = `/tmp/luau-cicd-test-{timestamp}`
            fs.writeDir(tempDir)
        end)

        afterAll(function()
            -- Clean up temp directory
            if tempDir and fs.isDir(tempDir) then
                process.exec("rm", { "-rf", tempDir })
            end
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

            const section = extractChangelog("1.0.0", changelogPath)
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

            const section = extractChangelog("2.0.0", changelogPath)
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

            const section = extractChangelog("1.0.0", changelogPath)
            expect(section).to.be.ok()
            expect(string.find(section :: string, "Last version content")).to.be.ok()
        end)
    end)
end
