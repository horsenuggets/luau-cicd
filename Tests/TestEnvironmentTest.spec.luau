--[[

TestEnvironmentTest.spec

Tests the isolated environment helper and its runtime parameter validation.

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

    it("should remove shared indentation without changing relative indentation", function()
        expect(TestEnvironment.dedent("\n    First\n        Second\n")).to.equal("First\n    Second\n")
        expect(TestEnvironment.dedent("")).to.equal("")
    end)

    it("should quote strings on a single line with escaped control characters", function()
        expect(TestEnvironment.quote("plain")).to.equal('"plain"')
        expect(TestEnvironment.quote("a\nb\rc\td")).to.equal('"a\\nb\\rc\\td"')
        expect(TestEnvironment.quote('say "hi" \\')).to.equal('"say \\"hi\\" \\\\"')
        expect(TestEnvironment.quote("\0")).to.equal('"\\x00"')
    end)

    it("should create and read files through the environment API", function()
        env.WriteDir("Source")
        env.WriteFile("Source/Module.luau", "return {}\n")
        expect(env.FileExists("Source/Module.luau")).to.equal(true)
        expect(env.ReadFile("Source/Module.luau")).to.equal("return {}\n")
    end)

    it("should reject non-string input before performing file or process operations", function()
        const calls = {
            function()
                TestEnvironment.dedent(123 :: any)
            end,
            function()
                env.FileExists(123 :: any)
            end,
            function()
                env.GitCommit(123 :: any)
            end,
            function()
                env.GitTag(123 :: any)
            end,
            function()
                env.ReadFile(123 :: any)
            end,
            function()
                env.RunScript(123 :: any)
            end,
            function()
                env.WriteDir(123 :: any)
            end,
            function()
                env.WriteFile(123 :: any, "content")
            end,
            function()
                env.WriteFile("Module.luau", 123 :: any)
            end
        }

        for _, call in calls do
            const ok = pcall(call)
            expect(ok).to.equal(false)
        end
    end)

    it("should reject invalid script argument arrays before launching a process", function()
        for _, args in { 123, { 123 } } do
            const ok = pcall(function()
                env.RunScript("RunTests", args :: any)
            end)
            expect(ok).to.equal(false)
        end
    end)
end
