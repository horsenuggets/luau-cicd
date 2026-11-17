--[[

CheckReleaseTitleVersionTest.spec

Tests for the CheckReleaseTitleVersion script, which compares a PR title with "VERSION".

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

const TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should pass when the title matches VERSION", function()
        env.WriteFile("VERSION", "1.2.3\n")
        const result = env.RunScript("CheckReleaseTitleVersion", { "Release 1.2.3" })
        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, 'PR title matches the "VERSION" file.', 1, true)).to.be.ok()
    end)

    it("should ignore surrounding whitespace in VERSION", function()
        env.WriteFile("VERSION", "  1.2.3  \n\n")
        const result = env.RunScript("CheckReleaseTitleVersion", { "Release 1.2.3" })
        expect(result.ok).to.equal(true)
    end)

    for _, title in { "Release 1.2.4", "Release 1.2.3 ", "1.2.3" } do
        it(`should fail for {TestEnvironment.quote(title)}`, function()
            env.WriteFile("VERSION", "1.2.3\n")
            const result = env.RunScript("CheckReleaseTitleVersion", { title })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, 'Expected "Release 1.2.3".', 1, true)).to.be.ok()
        end)
    end

    it("should fail when VERSION is missing", function()
        const result = env.RunScript("CheckReleaseTitleVersion", { "Release 1.2.3" })
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, 'The "VERSION" file does not exist.', 1, true)).to.be.ok()
    end)

    it("should print usage without a title", function()
        env.WriteFile("VERSION", "1.2.3\n")
        const result = env.RunScript("CheckReleaseTitleVersion")
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
    end)
end
