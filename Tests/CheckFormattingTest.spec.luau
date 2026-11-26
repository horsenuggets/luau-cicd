--[[

CheckFormattingTest.spec

Tests for the CheckFormatting script.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

const TestEnvironment = require("./Helpers/TestEnvironment")
const process = require("@lune/process")

const dedent = TestEnvironment.dedent

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
        -- Create a styluau.toml so StyLuau knows to format.
        env.WriteFile(
            "styluau.toml",
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

    const function writeStub(binary: string, body: string)
        assert(type(binary) == "string", "Expected a binary string.")
        assert(type(body) == "string", "Expected a script body string.")

        env.WriteFile(`bin/{binary}`, body)
        const result = process.exec("chmod", { "+x", `{env.Path}/bin/{binary}` })
        assert(result.ok, result.stderr)
    end

    const function runWithStubs(args: { string }?): TestEnvironment.ExecResult
        assert(args == nil or type(args) == "table", "Expected an optional argument array.")

        const lune = process.exec("which", { "lune" })
        assert(lune.ok, lune.stderr)
        env.WriteDir("bin")
        const link = process.exec("ln", { "-s", string.match(lune.stdout, "^%s*(.-)%s*$"), `{env.Path}/bin/lune` })
        assert(link.ok, link.stderr)

        return env.RunScript("CheckFormatting", args, {
            CALL_LOG = `{env.Path}/calls.txt`,
            PATH = `{env.Path}/bin`
        })
    end

    it("should prefer StyLuau when both executables are usable", function()
        writeStub("styluau", '#!/bin/sh\nprintf "%s\\n" "$@" >> "$CALL_LOG"\n')
        writeStub("stylua", '#!/bin/sh\nprintf "unexpected\\n" >> "$CALL_LOG"\n')
        const result = runWithStubs()
        expect(result.ok).to.equal(true)
        expect(env.ReadFile("calls.txt")).to.equal("--version\n--check\n.\n")
        expect(result.stdout).to.contain('Checking formatting with "styluau".')
    end)

    it("should use StyLua after an unsuccessful StyLuau probe", function()
        writeStub("styluau", "#!/bin/sh\nexit 1\n")
        writeStub("stylua", '#!/bin/sh\nprintf "%s\\n" "$@" >> "$CALL_LOG"\n')
        const result = runWithStubs()
        expect(result.ok).to.equal(true)
        expect(env.ReadFile("calls.txt")).to.equal("--version\n--check\n.\n")
        expect(result.stdout).to.contain('Checking formatting with "stylua".')
    end)

    it("should use StyLua after a StyLuau spawn error", function()
        writeStub("styluau", "#!/nonexistent-formatter-interpreter\n")
        writeStub("stylua", "#!/bin/sh\nexit 0\n")
        const result = runWithStubs()
        expect(result.ok).to.equal(true)
        expect(result.stdout).to.contain('Checking formatting with "stylua".')
    end)

    it("should report when neither formatter is usable", function()
        writeStub("styluau", "#!/bin/sh\nexit 1\n")
        writeStub("stylua", "#!/nonexistent-formatter-interpreter\n")
        const result = runWithStubs()
        expect(result.ok).to.equal(false)
        expect(result.stderr).to.contain('Neither "styluau" nor "stylua" is usable.')
    end)

    it("should report when neither formatter is installed", function()
        const result = runWithStubs()
        expect(result.ok).to.equal(false)
        expect(result.stderr).to.contain('Neither "styluau" nor "stylua" is usable.')
    end)

    it("should use StyLua when it is the only installed formatter", function()
        writeStub("stylua", "#!/bin/sh\nexit 0\n")
        const result = runWithStubs()
        expect(result.ok).to.equal(true)
        expect(result.stdout).to.contain('Checking formatting with "stylua".')
    end)

    it("should honor an explicit binary without probing", function()
        writeStub("styluau", "#!/bin/sh\nexit 0\n")
        writeStub("custom-formatter", '#!/bin/sh\nprintf "%s\\n" "$@" >> "$CALL_LOG"\n')
        const result = runWithStubs({ "custom-formatter" })
        expect(result.ok).to.equal(true)
        expect(env.ReadFile("calls.txt")).to.equal("--check\n.\n")
    end)

    it("should pass a binary path containing spaces as one executable", function()
        writeStub("formatter with spaces", '#!/bin/sh\nprintf "%s\\n" "$@" >> "$CALL_LOG"\n')
        const result = runWithStubs({ `{env.Path}/bin/formatter with spaces` })
        expect(result.ok).to.equal(true)
        expect(env.ReadFile("calls.txt")).to.equal("--check\n.\n")
    end)

    it("should not fall back after an explicit binary fails to spawn", function()
        writeStub("styluau", "#!/bin/sh\nexit 0\n")
        const result = runWithStubs({ `{env.Path}/missing-formatter` })
        expect(result.ok).to.equal(false)
        expect(result.stderr).to.contain("Could not run formatter")
    end)

    it("should preserve diagnostics without falling back after a formatting failure", function()
        writeStub(
            "styluau",
            '#!/bin/sh\nif [ "$1" = "--version" ]; then exit 0; fi\nprintf "format diff\\n"\nprintf "parse error\\n" >&2\nexit 1\n'
        )
        writeStub("stylua", "#!/bin/sh\nexit 0\n")
        const result = runWithStubs()
        expect(result.ok).to.equal(false)
        expect(result.stdout).to.contain("Formatting check failed.")
        expect(result.stdout).to.contain("format diff")
        expect(result.stdout).to.contain("parse error")
    end)

    it("should reject extra arguments and empty binary names", function()
        for _, args in { { "styluau", "unexpected" }, { "" } } do
            const result = env.RunScript("CheckFormatting", args)
            expect(result.ok).to.equal(false)
            expect(result.stderr).to.contain("[Usage] CheckFormatting.exec.luau [binary]")
        end
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

    it("should respect StyLuau ignore directives", function()
        -- Only StyLuau recognizes the bracketed directive, so StyLua would flag this file.
        env.WriteFile(
            "ignored.luau",
            dedent([[
                    -- [styluau] ignore
                    const   matrix   =   { 1,2,3 }
                    return matrix
                ]])
        )

        const result = env.RunScript("CheckFormatting")

        expect(result.ok).to.equal(true)
    end)

    it("should still flag code after a StyLuau ignore directive", function()
        env.WriteFile(
            "partial.luau",
            dedent([[
                    -- [styluau] ignore
                    const   matrix   =   { 1,2,3 }
                    const   other   =   2
                    return { matrix, other }
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
