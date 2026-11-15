--[[

CheckFormattingTest.spec

Tests for the CheckFormatting script.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

const dedent = TestEnvironment.dedent

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
        -- Create a stylua.toml so stylua knows to format.
        env.WriteFile(
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
        env.Cleanup()
    end)

    it("should pass when all files are formatted", function()
        env.WriteFile(
            "test.luau",
            dedent([[
                    const function hello()
                        print("Hello, world!")
                    end

                    return hello
                ]])
        )

        const result = env.RunScript("CheckFormatting")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "Formatting check passed")).to.be.ok()
    end)

    it("should fail when files are not formatted", function()
        -- Write poorly formatted code (inconsistent spacing).
        env.WriteFile(
            "test.luau",
            dedent([[
                    const function hello()
                    print("Hello, world!")
                        end

                    return hello
                ]])
        )

        const result = env.RunScript("CheckFormatting")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Formatting check failed")).to.be.ok()
    end)

    it("should check multiple files", function()
        env.WriteFile(
            "file1.luau",
            dedent([[
                    const a = 1
                    return a
                ]])
        )
        env.WriteFile(
            "file2.luau",
            dedent([[
                    const b = 2
                    return b
                ]])
        )

        const result = env.RunScript("CheckFormatting")

        expect(result.ok).to.equal(true)
    end)

    it("should fail if any file is unformatted", function()
        env.WriteFile(
            "good.luau",
            dedent([[
                    const a = 1
                    return a
                ]])
        )
        -- Use incorrect indentation to test invalid formatting.
        env.WriteFile(
            "bad.luau",
            dedent([[
                    const function test()
                    if true then
                    print("bad")
                    end
                    end
                    return test
                ]])
        )

        const result = env.RunScript("CheckFormatting")

        expect(result.ok).to.equal(false)
    end)

    it("should check files in subdirectories", function()
        env.WriteDir("subdir")
        env.WriteFile(
            "subdir/nested.luau",
            dedent([[
                    const nested = true
                    return nested
                ]])
        )

        const result = env.RunScript("CheckFormatting")

        expect(result.ok).to.equal(true)
    end)
end
