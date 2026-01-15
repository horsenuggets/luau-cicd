--[[

CheckLuaurcFormatTest

Tests for the CheckLuaurcFormat script.

--]]

local TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    describe("CheckLuaurcFormat", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.cleanup()
        end)

        describe("self alias validation", function()
            it("should pass when no self alias is present", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "devpackages": "DevPackages/"
    }
}]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

                expect(result.ok).to.equal(true)
                expect(string.find(result.stdout, "format is valid")).to.be.ok()
            end)

            it("should fail when self alias is present", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "self": "Source/",
        "devpackages": "DevPackages/"
    }
}]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "@self is built%-in")).to.be.ok()
            end)

            it("should fail when @self alias is present", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "@self": "Source/",
        "devpackages": "DevPackages/"
    }
}]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "@self is built%-in")).to.be.ok()
            end)

            it("should fail when Self alias is present (case insensitive)", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "Self": "Source/"
    }
}]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "@self is built%-in")).to.be.ok()
            end)
        end)

        describe("lune version validation", function()
            it("should pass when lune alias matches rokit.toml version", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "lune": "~/.lune/.typedefs/0.10.5/",
        "devpackages": "DevPackages/"
    }
}]=]
                )
                env.writeFile(
                    "test-rokit.toml",
                    [=[
[tools]
lune = "horsenuggets/lune@0.10.5"
stylua = "johnnymorganz/stylua@2.3.1"
]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

                expect(result.ok).to.equal(true)
            end)

            it("should fail when lune alias version does not match rokit.toml", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "lune": "~/.lune/.typedefs/0.9.0/",
        "devpackages": "DevPackages/"
    }
}]=]
                )
                env.writeFile(
                    "test-rokit.toml",
                    [=[
[tools]
lune = "horsenuggets/lune@0.10.5"
]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "does not match rokit.toml version")).to.be.ok()
                expect(string.find(result.stdout, "0.10.5")).to.be.ok()
            end)

            it("should fail when lune is in rokit.toml but no alias in luaurc", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "devpackages": "DevPackages/"
    }
}]=]
                )
                env.writeFile(
                    "test-rokit.toml",
                    [=[
[tools]
lune = "horsenuggets/lune@0.10.5"
]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "no lune alias found")).to.be.ok()
            end)

            it("should pass when no lune in rokit.toml and no lune alias", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "devpackages": "DevPackages/"
    }
}]=]
                )
                env.writeFile(
                    "test-rokit.toml",
                    [=[
[tools]
stylua = "johnnymorganz/stylua@2.3.1"
]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "test-rokit.toml" })

                expect(result.ok).to.equal(true)
            end)

            it("should pass when rokit.toml does not exist", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {
        "devpackages": "DevPackages/"
    }
}]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

                expect(result.ok).to.equal(true)
            end)
        end)

        describe("general validation", function()
            it("should pass when aliases section is empty", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "aliases": {}
}]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

                expect(result.ok).to.equal(true)
            end)

            it("should pass when no aliases section exists", function()
                env.writeFile(
                    "test.luaurc",
                    [=[{
    "globals": ["describe", "it", "expect"]
}]=]
                )

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc", "nonexistent.toml" })

                expect(result.ok).to.equal(true)
            end)

            it("should fail when file does not exist", function()
                local result = env.runScript("CheckLuaurcFormat", { "nonexistent.luaurc" })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "not found")).to.be.ok()
            end)

            it("should fail when file is not valid JSON", function()
                env.writeFile("test.luaurc", "this is not json")

                local result = env.runScript("CheckLuaurcFormat", { "test.luaurc" })

                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "Failed to parse")).to.be.ok()
            end)
        end)
    end)
end
