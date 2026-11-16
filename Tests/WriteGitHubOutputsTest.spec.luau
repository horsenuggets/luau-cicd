--[[

WriteGitHubOutputsTest.spec

Tests for the WriteGitHubOutputs helper, covering sorted output, appending, and rejection
of names and values that could inject extra outputs.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")
const WriteGitHubOutputs = require("../Scripts/Helpers/WriteGitHubOutputs.func")

return function()
    local env: TestEnvironment.Environment
    local outputPath: string

    beforeEach(function()
        env = TestEnvironment.create()
        outputPath = `{env.Path}/github-output`
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should write outputs in sorted key order", function()
        WriteGitHubOutputs(outputPath, { version = "1.2.3", archive = "a.zip", tag = "1.2.3" })
        expect(env.ReadFile("github-output")).to.equal("archive=a.zip\ntag=1.2.3\nversion=1.2.3\n")
    end)

    it("should produce identical output for identical input", function()
        WriteGitHubOutputs(outputPath, { b = "2", a = "1" })
        const first = env.ReadFile("github-output")
        WriteGitHubOutputs(`{env.Path}/second-output`, { b = "2", a = "1" })
        expect(env.ReadFile("second-output")).to.equal(first)
    end)

    it("should append to an existing file", function()
        env.WriteFile("github-output", "earlier=value\n")
        WriteGitHubOutputs(outputPath, { later = "value" })
        expect(env.ReadFile("github-output")).to.equal("earlier=value\nlater=value\n")
    end)

    for _, value in { "a\nb=c", "a\rb" } do
        it(`should reject the value {TestEnvironment.quote(value)}`, function()
            expect(function()
                WriteGitHubOutputs(outputPath, { key = value })
            end).to.throw()
            expect(env.FileExists("github-output")).to.equal(false)
        end)
    end

    for _, key in { "", "a=b", "a b", "a\nb" } do
        it(`should reject the key {TestEnvironment.quote(key)}`, function()
            expect(function()
                WriteGitHubOutputs(outputPath, { [key] = "value" })
            end).to.throw()
        end)
    end
end
