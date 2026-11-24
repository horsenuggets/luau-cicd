--[[

CheckFileHeadersTest.spec

Tests for the CheckFileHeaders script.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, describe, expect, it =
    Testable.afterEach, Testable.beforeEach, Testable.describe, Testable.expect, Testable.it

const TestEnvironment = require("./Helpers/TestEnvironment")
const process = require("@lune/process")

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    describe("valid headers", function()
        it("should pass for a file with a valid header", function()
            env.WriteFile(
                "MyModule.luau",
                [=[--[[

MyModule

This is a description of the module.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "1 file")).to.be.ok()
        end)

        it("should pass for a file with directives at the top", function()
            env.WriteFile(
                "StrictModule.luau",
                [=[--!strict

--[[

StrictModule

This is a module with strict mode enabled.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
        end)

        it("should pass for a file with multiple directives", function()
            env.WriteFile(
                "OptimizedModule.luau",
                [=[--!strict
--!native
--!optimize 2

--[[

OptimizedModule

This module has multiple directives.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
        end)

        it("should pass for a file with a shebang", function()
            env.WriteFile(
                "Script.luau",
                [=[#!/usr/bin/env lune

--[[

Script

This is an executable script.

--]]

print("Hello")
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
        end)

        it("should pass for a file with multi-paragraph description", function()
            env.WriteFile(
                "ComplexModule.luau",
                [=[--[[

ComplexModule

This is the first paragraph of the description.

This is the second paragraph of the description.
> Arguments are optional.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
        end)

        it("should use parent folder name for init.luau", function()
            env.WriteDir("MyFolder")
            env.WriteFile(
                "MyFolder/init.luau",
                [=[--[[

MyFolder

This is the init file for MyFolder.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
        end)

        it("should keep sub-extension for spec files", function()
            env.WriteFile(
                "MyTest.spec.luau",
                [=[--[[

MyTest.spec

Tests for MyTest.

--]]

return function() end
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
        end)
    end)

    describe("invalid headers", function()
        it("should fail when missing blank line after directives", function()
            env.WriteFile(
                "BadDirective.luau",
                [=[--!strict
--[[

BadDirective

Missing blank line after directive.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "blank line after directives")).to.be.ok()
        end)

        it("should fail when missing header comment", function()
            env.WriteFile(
                "NoHeader.luau",
                [=[local function foo()
    return "bar"
end

return foo
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, 'Expected "%-%-%[%["')).to.be.ok()
        end)

        it("should fail when module name does not match filename", function()
            env.WriteFile(
                "ActualName.luau",
                [=[--[[

WrongName

This module has the wrong name.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "does not match expected")).to.be.ok()
        end)

        it("should fail when missing description", function()
            env.WriteFile(
                "NoDescription.luau",
                [=[--[[

NoDescription

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Expected description")).to.be.ok()
        end)

        it("should fail when line exceeds 90 characters", function()
            env.WriteFile(
                "LongLine.luau",
                [=[--[[

LongLine

This is a very long description line that definitely exceeds the ninety character limit wow.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "exceeds 90 characters")).to.be.ok()
        end)

        it("should fail when missing blank line before closing", function()
            env.WriteFile(
                "NoBlankBeforeClose.luau",
                [=[--[[

NoBlankBeforeClose

This description has no blank line before closing.
--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, 'blank line before "%-%-%]%]"')).to.be.ok()
        end)

        it("should fail when init.luau uses wrong name", function()
            env.WriteDir("MyFolder")
            env.WriteFile(
                "MyFolder/init.luau",
                [=[--[[

init

Using init instead of folder name.

--]]

return {}
]=]
            )

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "does not match expected")).to.be.ok()
        end)
    end)

    it("should preserve init subextensions except actual Rojo entrypoints", function()
        for _, stem in { "init.spec", "init.func", "init.story", "init.legacy", "init.exec" } do
            env.WriteFile(`Modules/{stem}.luau`, `--[[\n\n{stem}\n\nValid module.\n\n--]]\n\nreturn \{\}\n`)
        end
        for _, stem in { "init", "init.server", "init.client", "init.plugin" } do
            env.WriteFile(`Modules/{stem}.luau`, "--[[\n\nModules\n\nValid entrypoint.\n\n--]]\n\nreturn {}\n")
        end
        const result = env.RunScript("CheckFileHeaders")
        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "9 files", 1, true)).to.be.ok()

        env.WriteFile("Modules/init.spec.luau", "--[[\n\nModules\n\nWrong header.\n\n--]]\n\nreturn {}\n")
        const invalidResult = env.RunScript("CheckFileHeaders")
        expect(invalidResult.ok).to.equal(false)
        expect(string.find(invalidResult.stdout, "init.spec", 1, true)).to.be.ok()
    end)

    describe("exclusions", function()
        it("should skip root init.luau files", function()
            env.WriteFile("init.luau", "return {}")

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "0 file")).to.be.ok()
        end)

        it("should validate module init headers in targeted subfolder scans", function()
            env.WriteFile("Source/MyModule/init.luau", "return {}\n")
            for _, directory in { "Source/MyModule", `{env.Path}/Source/MyModule` } do
                const result = env.RunScript("CheckFileHeaders", { directory })
                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "init.luau", 1, true)).to.be.ok()
            end
            env.WriteFile("Source/MyModule/init.luau", "--[[\n\nMyModule\n\nValid module.\n\n--]]\n\nreturn {}\n")
            const result = env.RunScript("CheckFileHeaders", { "Source/MyModule" })
            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "1 file", 1, true)).to.be.ok()
        end)

        it("should skip files in excluded directories", function()
            env.WriteDir("DevPackages")
            env.WriteFile("DevPackages/SomePackage.luau", "return {}")

            const result = env.RunScript("CheckFileHeaders", { env.Path })

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "0 file")).to.be.ok()
        end)

        it("should skip root build output when scanning the whole repo", function()
            env.WriteDir("Build")
            env.WriteFile("Build/fixture.luau", "return {}")

            const result = env.RunScript("CheckFileHeaders")

            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "0 file")).to.be.ok()
        end)

        it("should preserve root exclusions for equivalent directory arguments", function()
            for _, folder in { "Build", ".wt/feature/example", ".worktrees/example" } do
                env.WriteFile(`{folder}/Invalid.luau`, "return {}\n")
            end

            const cwdResult = process.exec("lune", { "run", "-" }, {
                cwd = env.Path,
                stdio = { stdin = 'print(require("@lune/process").cwd)' }
            })
            expect(cwdResult.ok).to.equal(true)
            const root = string.match(cwdResult.stdout, "^%s*(.-)%s*$") :: string
            for _, directory in { ".", "./", "././", "Build/../", root, `{root}/`, `{root}/./` } do
                const result = env.RunScript("CheckFileHeaders", { directory })
                expect(result.ok).to.equal(true)
                expect(string.find(result.stdout, "0 files", 1, true)).to.be.ok()
            end
        end)

        it("should still validate generated-looking directories below a scanned subfolder", function()
            for _, folder in { "Build", ".wt", ".worktrees" } do
                env.WriteFile(`Source/{folder}/Invalid.luau`, "return {}\n")
            end

            for _, directory in { "Source", "./Source/", `{env.Path}/Source/` } do
                const result = env.RunScript("CheckFileHeaders", { directory })
                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "3 files with invalid headers", 1, true)).to.be.ok()
            end
        end)

        it("should still check a Build folder when scanning a subfolder", function()
            env.WriteDir("Commands")
            env.WriteDir("Commands/Build")
            env.WriteFile("Commands/Build/init.luau", "return {}")

            const result = env.RunScript("CheckFileHeaders", { `{env.Path}/Commands` })

            expect(result.ok).to.equal(false)
            -- Paths in the report are relative to the scanned folder.
            expect(string.find(result.stdout, "Build/init.luau", 1, true)).to.be.ok()
        end)
    end)
end
