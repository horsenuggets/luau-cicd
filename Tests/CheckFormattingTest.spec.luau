--[[

CheckFormattingTest

Tests for the CheckFormatting script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

local dedent = TestEnvironment.dedent

return function()
    describe("CheckFormatting", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
            -- Create a stylua.toml so stylua knows to format
            env.writeFile(
                "stylua.toml",
                dedent([[
                    syntax = "Luau"
                    column_width = 120
                    line_endings = "Unix"
                    indent_type = "Spaces"
                    indent_width = 4
                    quote_style = "AutoPreferDouble"
                ]])
            )
        end)

        afterEach(function()
            env.cleanup()
        end)

        it("should pass when all files are formatted", function()
            env.writeFile(
                "test.luau",
                dedent([[
                    local function hello()
                        print("Hello, world!")
                    end

                    return hello
                ]])
            )

            local result = env.runScript("CheckFormatting")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "Formatting check passed")).to.be.ok()
        end)

        it("should fail when files are not formatted", function()
            -- Write poorly formatted code (inconsistent spacing)
            env.writeFile(
                "test.luau",
                dedent([[
                    local function hello()
                    print("Hello, world!")
                        end

                    return hello
                ]])
            )

            local result = env.runScript("CheckFormatting")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Formatting check failed")).to.be.ok()
        end)

        it("should check multiple files", function()
            env.writeFile(
                "file1.luau",
                dedent([[
                    local a = 1
                    return a
                ]])
            )
            env.writeFile(
                "file2.luau",
                dedent([[
                    local b = 2
                    return b
                ]])
            )

            local result = env.runScript("CheckFormatting")

            expect(result.ok).to.equal(true)
        end)

        it("should fail if any file is unformatted", function()
            env.writeFile(
                "good.luau",
                dedent([[
                    local a = 1
                    return a
                ]])
            )
            -- Bad formatting - wrong indentation
            env.writeFile(
                "bad.luau",
                dedent([[
                    local function test()
                    if true then
                    print("bad")
                    end
                    end
                    return test
                ]])
            )

            local result = env.runScript("CheckFormatting")

            expect(result.ok).to.equal(false)
        end)

        it("should check files in subdirectories", function()
            env.writeDir("subdir")
            env.writeFile(
                "subdir/nested.luau",
                dedent([[
                    local nested = true
                    return nested
                ]])
            )

            local result = env.runScript("CheckFormatting")

            expect(result.ok).to.equal(true)
        end)
    end)
end
