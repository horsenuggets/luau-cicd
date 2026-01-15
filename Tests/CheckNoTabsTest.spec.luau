--[[

CheckNoTabsTest

Tests for the CheckNoTabs script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

-- Helper to create content with tabs (using \t escape in regular strings)
local TAB = "\t"

return function()
    describe("CheckNoTabs", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should pass when file uses spaces for indentation", function()
            env.writeFile(
                "test.luau",
                [=[--[[

Test

Description here.

--]]

local function foo()
    return "bar"
end

return foo
]=]
            )

            local result = env.runScript("CheckNoTabs", { env.path })

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "use spaces")).to.be.ok()
        end)

        it("should fail when file contains tabs", function()
            local content = "--[[\n\nTest\n\nDescription.\n\n--]]\n\nlocal function foo()\n"
                .. TAB
                .. 'return "bar"\nend\n\nreturn foo\n'
            env.writeFile("test.luau", content)

            local result = env.runScript("CheckNoTabs", { env.path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "file.*with tabs")).to.be.ok()
        end)

        it("should report multiple lines with tabs", function()
            local content = "--[[\n\nTest\n\nDescription.\n\n--]]\n\nlocal function foo()\n"
                .. TAB
                .. "local a = 1\n"
                .. TAB
                .. "local b = 2\n"
                .. TAB
                .. "return a + b\nend\n\nreturn foo\n"
            env.writeFile("test.luau", content)

            local result = env.runScript("CheckNoTabs", { env.path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Lines with tabs")).to.be.ok()
        end)

        it("should check multiple files", function()
            env.writeFile(
                "good.luau",
                [=[--[[

Good

Description here.

--]]

return {}
]=]
            )
            local badContent = "--[[\n\nBad\n\nDescription.\n\n--]]\n\nreturn {\n" .. TAB .. "value = 1\n}\n"
            env.writeFile("bad.luau", badContent)

            local result = env.runScript("CheckNoTabs", { env.path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "bad.luau")).to.be.ok()
        end)

        it("should check files in subdirectories", function()
            local content = "--[[\n\nModule\n\nDescription.\n\n--]]\n\nreturn {\n" .. TAB .. "value = 1\n}\n"
            env.writeFile("Source/Module.luau", content)

            local result = env.runScript("CheckNoTabs", { env.path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Source/Module.luau")).to.be.ok()
        end)

        it("should skip excluded directories", function()
            local content = "--[[\n\ndep\n\nDescription.\n\n--]]\n\nreturn {\n" .. TAB .. "value = 1\n}\n"
            env.writeFile("DevPackages/dep.luau", content)

            local result = env.runScript("CheckNoTabs", { env.path })

            expect(result.ok).to.equal(true)
        end)

        it("should detect tabs anywhere in a line", function()
            local content = [=[--[[

Test

Description here.

--]]

local value = "hello]=] .. TAB .. [=[world"

return value
]=]
            env.writeFile("test.luau", content)

            local result = env.runScript("CheckNoTabs", { env.path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "with tabs")).to.be.ok()
        end)

        it("should pass when directory has no luau files", function()
            env.writeFile("readme.md", "# Test\n\nSome content.\n")

            local result = env.runScript("CheckNoTabs", { env.path })

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "0 file")).to.be.ok()
        end)
    end)
end
