--[[

CheckNoTabsTest.spec

Tests for the CheckNoTabs script.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

-- Helper to create content with tabs (using \t escape in regular strings).
const TAB = "\t"

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should pass when file uses spaces for indentation", function()
        env.WriteFile(
            "test.luau",
            [=[--[[

Test

Description here.

--]]

const function foo()
    return "bar"
end

return foo
]=]
        )

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "Validated space-only indentation in 1 file.", 1, true)).to.be.ok()
    end)

    it("should fail when file contains tabs", function()
        const content =
            `--[[\n\nTest\n\nDescription.\n\n--]]\n\nconst function foo()\n{TAB}return "bar"\nend\n\nreturn foo\n`
        env.WriteFile("test.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "file.*with tabs")).to.be.ok()
    end)

    it("should report multiple lines with tabs", function()
        const content =
            `--[[\n\nTest\n\nDescription.\n\n--]]\n\nconst function foo()\n{TAB}const a = 1\n{TAB}const b = 2\n{TAB}return a + b\nend\n\nreturn foo\n`
        env.WriteFile("test.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Tabs appear on lines 10, 11, 12.", 1, true)).to.be.ok()
    end)

    it("should check multiple files", function()
        env.WriteFile(
            "good.luau",
            [=[--[[

Good

Description here.

--]]

return {}
]=]
        )
        const badContent = `--[[\n\nBad\n\nDescription.\n\n--]]\n\nreturn \{\n{TAB}Value = 1\n\}\n`
        env.WriteFile("bad.luau", badContent)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "bad.luau")).to.be.ok()
    end)

    it("should check files in subdirectories", function()
        const content = `--[[\n\nModule\n\nDescription.\n\n--]]\n\nreturn \{\n{TAB}Value = 1\n\}\n`
        env.WriteFile("Source/Module.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Source/Module.luau")).to.be.ok()
    end)

    it("should skip excluded directories", function()
        const content = `--[[\n\nDep\n\nDescription.\n\n--]]\n\nreturn \{\n{TAB}Value = 1\n\}\n`
        env.WriteFile("DevPackages/dep.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(true)
    end)

    it("should detect tabs anywhere in a line", function()
        const content = `--[[\n\nTest\n\nDescription here.\n\n--]]\n\nconst value = "hello{TAB}world"\n\nreturn value\n`
        env.WriteFile("test.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "with tabs")).to.be.ok()
    end)

    it("should pass when directory has no luau files", function()
        env.WriteFile("readme.md", "# Test\n\nSome content.\n")

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "0 file")).to.be.ok()
    end)
end
