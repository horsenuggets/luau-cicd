--[[

CheckReleaseTitleTest.spec

Tests for the CheckReleaseTitle script, covering exact titles, near misses, and usage.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    for _, title in
        { "Release 1.2.3", "Release 0.0.1", "Release 10.20.30", "Release 2.0.0-beta.6", "Release 3.1.1-horse.0.5" }
    do
        it(`should accept "{title}"`, function()
            const result = env.RunScript("CheckReleaseTitle", { title })
            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "PR title is valid.", 1, true)).to.be.ok()
        end)
    end

    for _, title in
        {
            "",
            "Release",
            "Release v1.2.3",
            "Release 1.2",
            "Release 1.2.3 extra",
            "Release 1.2.3\n",
            " Release 1.2.3",
            "release 1.2.3",
            "Release  1.2.3",
            "Release 1.2.3-",
            "Release 1.2.3-beta 1",
            "Release 1.2.3-beta\n",
        }
    do
        it(`should reject {TestEnvironment.quote(title)}`, function()
            const result = env.RunScript("CheckReleaseTitle", { title })
            expect(result.ok).to.equal(false)
            expect(
                string.find(
                    result.stderr,
                    '::error::PR title must be exactly "Release X.Y.Z" or "Release X.Y.Z-suffix"',
                    1,
                    true
                )
            ).to.be.ok()
        end)
    end

    it("should print usage without a title", function()
        const result = env.RunScript("CheckReleaseTitle")
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
    end)
end
