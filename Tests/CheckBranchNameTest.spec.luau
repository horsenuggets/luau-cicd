--[[

CheckBranchNameTest.spec

Tests for the CheckBranchName script, covering valid names, malformed names, and usage.

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

    for _, branch in { "feature/my-feature", "ae/add-login", "any-prefix/name-2", "1/2" } do
        it(`should accept "{branch}"`, function()
            const result = env.RunScript("CheckBranchName", { branch })
            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "Branch name is valid.", 1, true)).to.be.ok()
        end)
    end

    for _, branch in
        {
            "",
            "main",
            "Feature/name",
            "feature/Name",
            "feature/a/b",
            "feature/",
            "/name",
            "feature/a--b",
            "feature/-name",
            "feature/name-",
            "feature/my_feature",
            "feature/name\n"
        }
    do
        it(`should reject {TestEnvironment.quote(branch)}`, function()
            const result = env.RunScript("CheckBranchName", { branch })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, "::error::Branch name must be", 1, true)).to.be.ok()
        end)
    end

    for _, args in { {}, { "feature/a", "feature/b" } } do
        it(`should print usage for {#args} arguments`, function()
            const result = env.RunScript("CheckBranchName", args)
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
        end)
    end
end
