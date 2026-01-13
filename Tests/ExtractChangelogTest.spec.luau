--[[

ExtractChangelogTest

Tests for the extractChangelog helper function.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local TestEnvironment = require("./Helpers/TestEnvironment")
local extractChangelog = require("../Scripts/Helpers/extractChangelog")

local dedent = TestEnvironment.dedent

return function()
    describe("extractChangelog", function()
        local tempDir: string

        beforeAll(function()
            -- Create a unique temp directory for this test suite
            local timestamp = tostring(os.time()) .. tostring(math.random(1000, 9999))
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
            local changelogPath = `{tempDir}/CHANGELOG.md`
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

            local section = extractChangelog("1.0.0", changelogPath)
            expect(section).to.be.ok()
            expect(string.find(section :: string, "Feature one")).to.be.ok()
            expect(string.find(section :: string, "Feature two")).to.be.ok()
        end)

        it("should return nil for non-existent version", function()
            local changelogPath = `{tempDir}/CHANGELOG2.md`
            fs.writeFile(
                changelogPath,
                dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Something
                ]])
            )

            local section = extractChangelog("2.0.0", changelogPath)
            expect(section).to.equal(nil)
        end)

        it("should extract last version in changelog", function()
            local changelogPath = `{tempDir}/CHANGELOG3.md`
            fs.writeFile(
                changelogPath,
                dedent([[
                    # Changelog

                    ## 1.0.0

                    ### Added

                    - Last version content
                ]])
            )

            local section = extractChangelog("1.0.0", changelogPath)
            expect(section).to.be.ok()
            expect(string.find(section :: string, "Last version content")).to.be.ok()
        end)
    end)
end
