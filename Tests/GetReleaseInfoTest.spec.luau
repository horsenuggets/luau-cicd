--[[

GetReleaseInfoTest.spec

Tests for the GetReleaseInfo script, covering the outputs it writes, the extracted notes,
and every way the inputs can be missing or malformed.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

const dedent = TestEnvironment.dedent

const CHANGELOG = dedent([[
    # Changelog

    ## 1.2.3

    - Current notes.
        Indented detail.

    ## 1.2.2

    - Older notes.
]])

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
        env.WriteDir("runner-temp")
    end)

    afterEach(function()
        env.Cleanup()
    end)

    const function run(): TestEnvironment.ExecResult
        return env.RunScript("GetReleaseInfo", nil, {
            GITHUB_OUTPUT = `{env.Path}/github-output`,
            RUNNER_TEMP = `{env.Path}/runner-temp`,
        })
    end

    it("should write the outputs and only the matching notes", function()
        env.WriteFile("VERSION", "1.2.3\n")
        env.WriteFile("CHANGELOG.md", CHANGELOG)

        const result = run()
        expect(result.ok).to.equal(true)
        expect(env.ReadFile("runner-temp/changelog.txt")).to.equal("- Current notes.\n    Indented detail.\n")
        expect(env.ReadFile("github-output")).to.equal(
            `notes_file={env.Path}/runner-temp/changelog.txt\ntag=1.2.3\nversion=1.2.3\n`
        )
    end)

    it("should append to existing outputs", function()
        env.WriteFile("VERSION", "1.2.3\n")
        env.WriteFile("CHANGELOG.md", CHANGELOG)
        env.WriteFile("github-output", "earlier=value\n")

        expect(run().ok).to.equal(true)
        expect(string.sub(env.ReadFile("github-output"), 1, 14)).to.equal("earlier=value\n")
    end)

    it("should support versions with a prerelease suffix", function()
        env.WriteFile("VERSION", "3.1.1-horse.0.5\n")
        env.WriteFile("CHANGELOG.md", "# Changelog\n\n## 3.1.1-horse.0.5\n\n- Fork notes.\n\n## 3.1.1\n\n- Old.\n")

        expect(run().ok).to.equal(true)
        expect(env.ReadFile("runner-temp/changelog.txt")).to.equal("- Fork notes.\n")
        expect(env.ReadFile("github-output")).to.equal(
            `notes_file={env.Path}/runner-temp/changelog.txt\ntag=3.1.1-horse.0.5\nversion=3.1.1-horse.0.5\n`
        )
    end)

    it("should not match a prerelease section for the plain version", function()
        env.WriteFile("VERSION", "3.1.1\n")
        env.WriteFile("CHANGELOG.md", "# Changelog\n\n## 3.1.1-horse.0.5\n\n- Fork notes.\n")

        expect(run().ok).to.equal(false)
    end)

    it("should fail when the version has no changelog section", function()
        env.WriteFile("VERSION", "3.2.1\n")
        env.WriteFile("CHANGELOG.md", CHANGELOG)

        const result = run()
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, 'Missing changelog notes for "3.2.1".', 1, true)).to.be.ok()
    end)

    it("should fail when the changelog section is empty", function()
        env.WriteFile("VERSION", "1.2.3\n")
        env.WriteFile("CHANGELOG.md", "# Changelog\n\n## 1.2.3\n\n## 1.2.2\n\n- Old notes.\n")

        expect(run().ok).to.equal(false)
    end)

    for _, version in { "1.2.3\ninjected=value", "v1.2.3", "1.2", "" } do
        it(`should reject the version {TestEnvironment.quote(version)} without writing outputs`, function()
            env.WriteFile("VERSION", `{version}\n`)
            env.WriteFile("CHANGELOG.md", CHANGELOG)

            const result = run()
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, "Invalid release version", 1, true)).to.be.ok()
            expect(env.FileExists("github-output")).to.equal(false)
        end)
    end

    it("should fail when VERSION is missing", function()
        env.WriteFile("CHANGELOG.md", CHANGELOG)
        expect(run().ok).to.equal(false)
    end)

    for _, missing in { "GITHUB_OUTPUT", "RUNNER_TEMP" } do
        it(`should fail when "{missing}" is not set`, function()
            env.WriteFile("VERSION", "1.2.3\n")
            env.WriteFile("CHANGELOG.md", CHANGELOG)

            const extraEnv = {
                GITHUB_OUTPUT = `{env.Path}/github-output`,
                RUNNER_TEMP = `{env.Path}/runner-temp`,
            }
            extraEnv[missing] = ""

            const result = env.RunScript("GetReleaseInfo", nil, extraEnv)
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, `The "{missing}" environment variable must be set.`, 1, true)).to.be.ok()
        end)
    end
end
