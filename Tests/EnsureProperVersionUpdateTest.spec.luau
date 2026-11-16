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

    for _, case in
        {
            { From = "1.70.1-horse.1.6", To = "1.70.1-horse.1.7", Ok = true },
            { From = "1.70.1-horse.1.6", To = "1.71.0-horse.1.7", Ok = true },
            { From = "2.0.0-beta.6", To = "2.0.0-beta.7", Ok = true },
            { From = "2.0.0-beta.6", To = "2.0.0", Ok = true },
            { From = "1.9.0", To = "2.0.0-beta.1", Ok = true },
            { From = "2.0.0-beta.7", To = "2.0.0-beta.6", Ok = false },
            { From = "2.0.0", To = "2.0.0-beta.9", Ok = false },
            { From = "1.70.1-horse.1.6", To = "1.70.1-horse.1.6", Ok = false },
        }
    do
        it(`should {if case.Ok then "accept" else "reject"} "{case.From}" to "{case.To}"`, function()
            env.WriteFile("VERSION", `{case.From}\n`)
            env.GitCommit("Previous release")
            env.GitTag(case.From)

            env.WriteFile("VERSION", `{case.To}\n`)
            env.GitCommit("Bump version")

            const result = env.RunScript("EnsureProperVersionUpdate")
            expect(result.ok).to.equal(case.Ok)
            if case.Ok then
                expect(string.find(result.stdout, "Valid prerelease version update.", 1, true)).to.be.ok()
            end
        end)
    end

    it("should pick the latest tag by SemVer precedence, not by text", function()
        env.WriteFile("VERSION", "1.0.0-beta.2\n")
        env.GitCommit("Beta 2")
        env.GitTag("1.0.0-beta.2")

        env.WriteFile("VERSION", "1.0.0-beta.10\n")
        env.GitCommit("Beta 10")
        env.GitTag("1.0.0-beta.10")

        env.WriteFile("VERSION", "1.0.0-beta.11\n")
        env.GitCommit("Beta 11")

        const result = env.RunScript("EnsureProperVersionUpdate")
        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, 'Latest release tag is "1.0.0-beta.10".', 1, true)).to.be.ok()
    end)

    it("should ignore tags that are not release versions", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.GitCommit("Initial commit")
        env.GitTag("1.0.0")
        env.GitTag("v9.9.9")
        env.GitTag("nightly")

        env.WriteFile("VERSION", "1.0.1\n")
        env.GitCommit("Bump version")

        const result = env.RunScript("EnsureProperVersionUpdate")
        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, 'Latest release tag is "1.0.0".', 1, true)).to.be.ok()
    end)
end
