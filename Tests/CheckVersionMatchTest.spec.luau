--[[

CheckVersionMatchTest.spec

Tests for the CheckVersionMatch script.

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

    it("should pass when versions match", function()
        env.WriteFile("VERSION", "1.2.3\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                    version = "1.2.3"
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, 'All versions match "1.2.3"')).to.be.ok()
    end)

    it("should fail when versions do not match", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Version mismatch")).to.be.ok()
    end)

    it("should handle VERSION with whitespace", function()
        env.WriteFile("VERSION", "  1.0.0  \n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(true)
    end)

    it("should fail when wally.toml has no version", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, 'Could not find the version in "wally.toml".', 1, true)).to.be.ok()
    end)

    it("should match versions with different formatting in wally.toml", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                    version="1.0.0"
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(true)
    end)

    it("should pass when README.md version matches", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "2.0.0"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    Install with `author/my-package@2.0.0`
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, 'All versions match "2.0.0"')).to.be.ok()
    end)

    it("should fail when README.md version does not match", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "2.0.0"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    Install with `author/my-package@1.0.0`
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Version mismatch")).to.be.ok()
        expect(string.find(result.stdout, "README.md")).to.be.ok()
    end)

    it("should pass when README.md has no package dependency string", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "2.0.0"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    This is a package without version strings.
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(true)
    end)

    it("should pass when README.md version matches with fork suffix", function()
        env.WriteFile("VERSION", "3.1.1-horse.0.3\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "3.1.1-horse.0.3"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    Install with `author/my-package@3.1.1-horse.0.3`
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, 'All versions match "3.1.1%-horse.0.3"')).to.be.ok()
    end)

    it("should fail when README.md fork version does not match", function()
        env.WriteFile("VERSION", "3.1.1-horse.0.4\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "3.1.1-horse.0.4"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    Install with `author/my-package@3.1.1-horse.0.3`
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Version mismatch")).to.be.ok()
    end)

    it("should pass when README.md version matches with prerelease suffix", function()
        env.WriteFile("VERSION", "2.0.0-beta.5\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "2.0.0-beta.5"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    Install with `author/my-package@2.0.0-beta.5`
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(true)
    end)

    it("should pass when README.md does not exist", function()
        env.WriteFile("VERSION", "1.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "1.0.0"
                ]])
        )

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(true)
    end)
end
