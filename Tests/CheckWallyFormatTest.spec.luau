--[[

CheckWallyFormatTest.spec

Tests for the CheckWallyFormat script.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

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

    it("should validate lowercase coordinates in server dependencies", function()
        for _, coordinate in { "owner/package@1.0.0", "Owner/Package@1.0.0" } do
            env.WriteFile(
                "test-wally.toml",
                `[package]\nname = "owner/package"\nversion = "1.0.0"\n\n[server-dependencies]\nService = "{coordinate}"\n`
            )

            const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })

            expect(result.ok).to.equal(coordinate == string.lower(coordinate))
            if not result.ok then
                expect(string.find(result.stdout, 'Dependency "Service"', 1, true)).to.be.ok()
                expect(string.find(result.stdout, "non-lowercase", 1, true)).to.be.ok()
            end
        end
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

    it("should validate package names independently of TOML quoting", function()
        for _, section in { "[package]", '["package"]', "['package']" } do
            for _, key in { "name", '"name"', "'name'" } do
                for _, quote in { '"', "'" } do
                    for _, coordinate in { "owner/package", "Owner/Package" } do
                        env.WriteFile("test-wally.toml", `{section}\n{key} = {quote}{coordinate}{quote}\n`)
                        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })
                        expect(result.ok).to.equal(coordinate == string.lower(coordinate))
                        if not result.ok then
                            expect(string.find(result.stdout, "Package name", 1, true)).to.be.ok()
                        end
                    end
                end
            end
        end
    end)

    it("should validate quoted keys and literal values in every dependency table", function()
        for _, section in { "dependencies", "dev-dependencies", "server-dependencies" } do
            for _, quote in { '"', "'" } do
                for _, coordinate in { "owner/package@1.0.0-horse.1.2", "Owner/Package@1.0.0-horse.1.2" } do
                    env.WriteFile(
                        "test-wally.toml",
                        `[{quote}{section}{quote}]\n{quote}Some Dependency{quote} = {quote}{coordinate}{quote}\n`
                    )
                    const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })
                    expect(result.ok).to.equal(coordinate == string.lower(coordinate))
                    if not result.ok then
                        expect(string.find(result.stdout, 'Dependency "Some Dependency"', 1, true)).to.be.ok()
                    end
                end
            end
        end
    end)

    it("should ignore commented assignments and unrelated sections", function()
        env.WriteFile(
            "test-wally.toml",
            "[package]\nname = 'owner/package'\n# name = 'Owner/Package'\ndescription = '''\n[dependencies]\nDependency = \"Owner/Package@1.0.0\"\n'''\n[metadata]\nname = 'Owner/Package'\nDependency = 'Owner/Package@1.0.0'\n"
        )
        const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })
        expect(result.ok).to.equal(true)
    end)

    it("should reject malformed TOML and invalid package or dependency value types", function()
        for _, case in
            {
                { Content = "[package\n", Message = 'Failed to parse "test-wally.toml" as TOML' },
                { Content = 'package = "invalid"\n', Message = 'Expected "package" to be a table' },
                { Content = "[package]\nname = 123\n", Message = "Expected Package name to be a string" },
                { Content = 'dependencies = "invalid"\n', Message = 'Expected "dependencies" to be a table' },
                {
                    Content = "[dev-dependencies]\nDependency = false\n",
                    Message = 'Expected Dependency "Dependency" to be a string',
                },
                {
                    Content = "[server-dependencies.Dependency]\n",
                    Message = 'Expected Dependency "Dependency" to be a string',
                },
            }
        do
            env.WriteFile("test-wally.toml", case.Content)
            const result = env.RunScript("CheckWallyFormat", { "test-wally.toml" })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, case.Message, 1, true)).to.be.ok()
        end
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
