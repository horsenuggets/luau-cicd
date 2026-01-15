--[[

CheckFileHeadersTest

Tests for the CheckFileHeaders script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    describe("CheckFileHeaders", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        describe("valid headers", function()
            it("should pass for a file with a valid header", function()
                env.writeFile(
                    "MyModule.luau",
                    [=[--[[

MyModule

This is a description of the module.

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
                expect(string.find(result.stdout, "1 file")).to.be.ok()
            end)

            it("should pass for a file with directives at the top", function()
                env.writeFile(
                    "StrictModule.luau",
                    [=[--!strict

--[[

StrictModule

This is a module with strict mode enabled.

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
            end)

            it("should pass for a file with multiple directives", function()
                env.writeFile(
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

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
            end)

            it("should pass for a file with a shebang", function()
                env.writeFile(
                    "Script.luau",
                    [=[#!/usr/bin/env lune

--[[

Script

This is an executable script.

--]]

print("Hello")
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
            end)

            it("should pass for a file with multi-paragraph description", function()
                env.writeFile(
                    "ComplexModule.luau",
                    [=[--[[

ComplexModule

This is the first paragraph of the description.

Usage: lune run ComplexModule [args]
  args: Optional arguments to pass.

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
            end)

            it("should use parent folder name for init.luau", function()
                env.writeDir("MyFolder")
                env.writeFile(
                    "MyFolder/init.luau",
                    [=[--[[

MyFolder

This is the init file for MyFolder.

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
            end)

            it("should strip .spec suffix for test files", function()
                env.writeFile(
                    "MyTest.spec.luau",
                    [=[--[[

MyTest

Tests for MyTest.

--]]

return function() end
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
            end)
        end)

        describe("invalid headers", function()
            it("should fail when missing blank line after directives", function()
                env.writeFile(
                    "BadDirective.luau",
                    [=[--!strict
--[[

BadDirective

Missing blank line after directive.

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "blank line after directives")).to.be.ok()
            end)

            it("should fail when missing header comment", function()
                env.writeFile(
                    "NoHeader.luau",
                    [=[local function foo()
    return "bar"
end

return foo
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, 'Expected "%-%-%[%["')).to.be.ok()
            end)

            it("should fail when module name does not match filename", function()
                env.writeFile(
                    "ActualName.luau",
                    [=[--[[

WrongName

This module has the wrong name.

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "does not match expected")).to.be.ok()
            end)

            it("should fail when missing description", function()
                env.writeFile(
                    "NoDescription.luau",
                    [=[--[[

NoDescription

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "Expected description")).to.be.ok()
            end)

            it("should fail when line exceeds 90 characters", function()
                env.writeFile(
                    "LongLine.luau",
                    [=[--[[

LongLine

This is a very long description line that definitely exceeds the ninety character limit wow.

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "exceeds 90 characters")).to.be.ok()
            end)

            it("should fail when missing blank line before closing", function()
                env.writeFile(
                    "NoBlankBeforeClose.luau",
                    [=[--[[

NoBlankBeforeClose

This description has no blank line before closing.
--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, 'blank line before "%-%-%]%]"')).to.be.ok()
            end)

            it("should fail when init.luau uses wrong name", function()
                env.writeDir("MyFolder")
                env.writeFile(
                    "MyFolder/init.luau",
                    [=[--[[

init

Using init instead of folder name.

--]]

return {}
]=]
                )

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "does not match expected")).to.be.ok()
            end)
        end)

        describe("exclusions", function()
            it("should skip root init.luau files", function()
                env.writeFile("init.luau", "return {}")

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
                expect(string.find(result.stdout, "0 file")).to.be.ok()
            end)

            it("should skip files in excluded directories", function()
                env.writeDir("DevPackages")
                env.writeFile("DevPackages/SomePackage.luau", "return {}")

                local result = env.runScript("CheckFileHeaders", { env.path })

                expect(result.ok).to.equal(true)
                expect(string.find(result.stdout, "0 file")).to.be.ok()
            end)
        end)
    end)
end
