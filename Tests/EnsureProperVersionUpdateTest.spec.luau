--[[

EnsureProperVersionUpdateTest.spec

Tests for the EnsureProperVersionUpdate script.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
        env.InitGit()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should pass with valid patch bump", function()
        -- Create initial version and tag.
        env.WriteFile("VERSION", "1.0.0\n")
        env.GitCommit("Initial commit")
        env.GitTag("1.0.0")

        -- Bump to patch version.
        env.WriteFile("VERSION", "1.0.1\n")
        env.GitCommit("Bump version")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "Valid patch version bump")).to.be.ok()
    end)

    it("should pass with valid minor bump", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.GitCommit("Initial commit")
        env.GitTag("1.0.0")

        env.WriteFile("VERSION", "1.1.0\n")
        env.GitCommit("Bump version")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "Valid minor version bump")).to.be.ok()
    end)

    it("should pass with valid major bump", function()
        env.WriteFile("VERSION", "1.2.3\n")
        env.GitCommit("Initial commit")
        env.GitTag("1.2.3")

        env.WriteFile("VERSION", "2.0.0\n")
        env.GitCommit("Bump version")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "Valid major version bump")).to.be.ok()
    end)

    it("should fail when version has not been updated", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.GitCommit("Initial commit")
        env.GitTag("1.0.0")

        -- Version unchanged.
        env.GitCommit("Another commit")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Version has not been updated")).to.be.ok()
    end)

    it("should fail with invalid version bump", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.GitCommit("Initial commit")
        env.GitTag("1.0.0")

        -- Invalid bump (skipping versions).
        env.WriteFile("VERSION", "1.0.5\n")
        env.GitCommit("Bad bump")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Invalid version bump")).to.be.ok()
    end)

    it("should fail with invalid VERSION format", function()
        env.WriteFile("VERSION", "not-a-version\n")
        env.GitCommit("Bad version")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "not in MAJOR.MINOR.PATCH format")).to.be.ok()
    end)

    it("should pass when no previous tags exist", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.GitCommit("Initial commit")
        -- No tags created.

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "No previous release tags found")).to.be.ok()
    end)

    it("should ignore 0.0.0 tag", function()
        env.WriteFile("VERSION", "0.0.0\n")
        env.GitCommit("Initial commit")
        env.GitTag("0.0.0")

        env.WriteFile("VERSION", "1.0.0\n")
        env.GitCommit("First release")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(true)
        -- Should report no previous tags since 0.0.0 is ignored.
        expect(string.find(result.stdout, "No previous release tags found")).to.be.ok()
    end)

    it("should fail when minor bump does not reset patch", function()
        env.WriteFile("VERSION", "1.0.5\n")
        env.GitCommit("Initial commit")
        env.GitTag("1.0.5")

        -- Minor bump but patch is not 0.
        env.WriteFile("VERSION", "1.1.5\n")
        env.GitCommit("Bad bump")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Invalid version bump")).to.be.ok()
    end)

    it("should fail when major bump does not reset minor and patch", function()
        env.WriteFile("VERSION", "1.2.3\n")
        env.GitCommit("Initial commit")
        env.GitTag("1.2.3")

        -- Major bump but minor/patch not reset.
        env.WriteFile("VERSION", "2.2.3\n")
        env.GitCommit("Bad bump")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Invalid version bump")).to.be.ok()
    end)

    it("should use most recent tag for comparison", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.GitCommit("v1")
        env.GitTag("1.0.0")

        env.WriteFile("VERSION", "1.1.0\n")
        env.GitCommit("v1.1")
        env.GitTag("1.1.0")

        -- Valid bump from 1.1.0 (not 1.0.0).
        env.WriteFile("VERSION", "1.1.1\n")
        env.GitCommit("v1.1.1")

        const result = env.RunScript("EnsureProperVersionUpdate")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "Valid patch version bump")).to.be.ok()
    end)
end
