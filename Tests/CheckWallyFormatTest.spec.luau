--[[

CheckWallyFormatTest.spec

Tests for the CheckWallyFormat script.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")

const dedent = TestEnvironment.dedent

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should pass when all repository strings are lowercase", function()
        env.WriteFile(
            "test-wally.toml",
            dedent([[
                    [package]
                    name = "owner/my-package"
                    version = "1.0.0"

                    [dependencies]
                    some-dep = "owner/package@1.0.0"

                    [dev-dependencies]
                    testable = "owner/testable@0.0.5"
                ]])
        )

        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, '"test-wally.toml" format is valid.', 1, true)).to.be.ok()
    end)

    it("should fail when package name has uppercase letters", function()
        env.WriteFile(
            "test-wally.toml",
            dedent([[
                    [package]
                    name = "Owner/my-package"
                    version = "1.0.0"
                ]])
        )

        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Package name")).to.be.ok()
        expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
    end)

    it("should fail when dependency has uppercase letters", function()
        env.WriteFile(
            "test-wally.toml",
            dedent([[
                    [package]
                    name = "owner/package"
                    version = "1.0.0"

                    [dependencies]
                    some-dep = "Owner/Package@1.0.0"
                ]])
        )

        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, 'Dependency "some%-dep"')).to.be.ok()
        expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
    end)

    it("should fail when dev-dependency has uppercase letters", function()
        env.WriteFile(
            "test-wally.toml",
            dedent([[
                    [package]
                    name = "owner/package"
                    version = "1.0.0"

                    [dev-dependencies]
                    testable = "Owner/Testable@0.0.5"
                ]])
        )

        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, 'Dependency "testable"')).to.be.ok()
        expect(string.find(result.stdout, "non%-lowercase")).to.be.ok()
    end)

    it("should fail when multiple values have uppercase letters", function()
        env.WriteFile(
            "test-wally.toml",
            dedent([[
                    [package]
                    name = "Owner/my-package"
                    version = "1.0.0"

                    [dependencies]
                    dep-one = "Owner/Package@1.0.0"

                    [dev-dependencies]
                    testable = "Owner/Testable@0.0.5"
                ]])
        )

        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "3 format error")).to.be.ok()
    end)

    it("should fail when file does not exist", function()
        const result = env.RunScript("CheckWallyFormat", { "nonexistent.toml" })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, '"nonexistent.toml" was not found.', 1, true)).to.be.ok()
    end)

    it("should pass when no dependencies section exists", function()
        env.WriteFile(
            "test-wally.toml",
            dedent([[
                    [package]
                    name = "owner/package"
                    version = "1.0.0"
                ]])
        )

        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

        expect(result.ok).to.equal(true)
    end)

    it("should not check other string fields like description", function()
        env.WriteFile(
            "test-wally.toml",
            dedent([[
                    [package]
                    name = "owner/package"
                    description = "This Has Uppercase Letters"
                    version = "1.0.0"
                ]])
        )

        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

        expect(result.ok).to.equal(true)
    end)

    it("should not check URL fields like registry and repository", function()
        env.WriteFile(
            "test-wally.toml",
            dedent([[
                    [package]
                    name = "owner/package"
                    version = "1.0.0"
                    registry = "https://example.com/Registry/Index"
                    repository = "https://example.com/Owner/Package"
                ]])
        )

        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

        expect(result.ok).to.equal(true)
    end)
end
