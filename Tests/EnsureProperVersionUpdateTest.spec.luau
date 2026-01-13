--[[

EnsureProperVersionUpdateTest

Tests for the EnsureProperVersionUpdate script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    describe("EnsureProperVersionUpdate", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
            env.initGit()
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should pass with valid patch bump", function()
            -- Create initial version and tag
            env.writeFile("VERSION", "1.0.0\n")
            env.gitCommit("Initial commit")
            env.gitTag("1.0.0")

            -- Bump to patch version
            env.writeFile("VERSION", "1.0.1\n")
            env.gitCommit("Bump version")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "Valid patch version bump")).to.be.ok()
        end)

        it("should pass with valid minor bump", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.gitCommit("Initial commit")
            env.gitTag("1.0.0")

            env.writeFile("VERSION", "1.1.0\n")
            env.gitCommit("Bump version")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "Valid minor version bump")).to.be.ok()
        end)

        it("should pass with valid major bump", function()
            env.writeFile("VERSION", "1.2.3\n")
            env.gitCommit("Initial commit")
            env.gitTag("1.2.3")

            env.writeFile("VERSION", "2.0.0\n")
            env.gitCommit("Bump version")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "Valid major version bump")).to.be.ok()
        end)

        it("should fail when version has not been updated", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.gitCommit("Initial commit")
            env.gitTag("1.0.0")

            -- Version unchanged
            env.gitCommit("Another commit")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Version has not been updated")).to.be.ok()
        end)

        it("should fail with invalid version bump", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.gitCommit("Initial commit")
            env.gitTag("1.0.0")

            -- Invalid bump (skipping versions)
            env.writeFile("VERSION", "1.0.5\n")
            env.gitCommit("Bad bump")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Invalid version bump")).to.be.ok()
        end)

        it("should fail with invalid VERSION format", function()
            env.writeFile("VERSION", "not-a-version\n")
            env.gitCommit("Bad version")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "not in MAJOR.MINOR.PATCH format")).to.be.ok()
        end)

        it("should pass when no previous tags exist", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.gitCommit("Initial commit")
            -- No tags created

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "No previous release tags found")).to.be.ok()
        end)

        it("should ignore 0.0.0 tag", function()
            env.writeFile("VERSION", "0.0.0\n")
            env.gitCommit("Initial commit")
            env.gitTag("0.0.0")

            env.writeFile("VERSION", "1.0.0\n")
            env.gitCommit("First release")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(true)
            -- Should report no previous tags since 0.0.0 is ignored
            expect(string.find(result.stdout, "No previous release tags found")).to.be.ok()
        end)

        it("should fail when minor bump does not reset patch", function()
            env.writeFile("VERSION", "1.0.5\n")
            env.gitCommit("Initial commit")
            env.gitTag("1.0.5")

            -- Minor bump but patch is not 0
            env.writeFile("VERSION", "1.1.5\n")
            env.gitCommit("Bad bump")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Invalid version bump")).to.be.ok()
        end)

        it("should fail when major bump does not reset minor and patch", function()
            env.writeFile("VERSION", "1.2.3\n")
            env.gitCommit("Initial commit")
            env.gitTag("1.2.3")

            -- Major bump but minor/patch not reset
            env.writeFile("VERSION", "2.2.3\n")
            env.gitCommit("Bad bump")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Invalid version bump")).to.be.ok()
        end)

        it("should use most recent tag for comparison", function()
            env.writeFile("VERSION", "1.0.0\n")
            env.gitCommit("v1")
            env.gitTag("1.0.0")

            env.writeFile("VERSION", "1.1.0\n")
            env.gitCommit("v1.1")
            env.gitTag("1.1.0")

            -- Valid bump from 1.1.0 (not 1.0.0)
            env.writeFile("VERSION", "1.1.1\n")
            env.gitCommit("v1.1.1")

            local result = env.runScript("EnsureProperVersionUpdate")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "Valid patch version bump")).to.be.ok()
        end)
    end)
end
