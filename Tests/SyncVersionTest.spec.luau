--[[

SyncVersionTest.spec

Tests for the SyncVersion script.

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

    it("should update wally.toml version to match VERSION file", function()
        env.WriteFile("VERSION", "1.2.3\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                    version = "0.0.0"
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const wallyContent = env.ReadFile("wally.toml")
        expect(string.find(wallyContent, 'version = "1.2.3"')).to.be.ok()
    end)

    it("should handle VERSION with trailing whitespace", function()
        env.WriteFile("VERSION", "  2.0.0  \n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const wallyContent = env.ReadFile("wally.toml")
        expect(string.find(wallyContent, 'version = "2.0.0"')).to.be.ok()
    end)

    it("should preserve other wally.toml content", function()
        env.WriteFile("VERSION", "3.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                    description = "A test package"
                    version = "1.0.0"
                    license = "MIT"

                    [dependencies]
                    something = "author/something@1.0.0"
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const wallyContent = env.ReadFile("wally.toml")
        expect(string.find(wallyContent, 'version = "3.0.0"')).to.be.ok()
        expect(string.find(wallyContent, 'name = "test/package"')).to.be.ok()
        expect(string.find(wallyContent, 'description = "A test package"')).to.be.ok()
        expect(string.find(wallyContent, 'license = "MIT"')).to.be.ok()
        expect(string.find(wallyContent, "something")).to.be.ok()
    end)

    it("should only update version in package section", function()
        env.WriteFile("VERSION", "5.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "test/package"
                    version = "1.0.0"

                    [dependencies]
                    dep = "author/dep@2.0.0"
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const wallyContent = env.ReadFile("wally.toml")
        expect(string.find(wallyContent, 'version = "5.0.0"')).to.be.ok()
        -- Dependency version should remain unchanged.
        expect(string.find(wallyContent, "dep@2.0.0")).to.be.ok()
    end)

    it("should update README.md version if package dependency string exists", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "1.0.0"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    ## Installation

                    Add to your `wally.toml`...

                    ```toml
                    [dependencies]
                    MyPackage = "author/my-package@1.0.0"
                    ```
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const readmeContent = env.ReadFile("README.md")
        expect(string.find(readmeContent, "author/my%-package@2%.0%.0")).to.be.ok()
    end)

    it("should update multiple README.md version references", function()
        env.WriteFile("VERSION", "3.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "1.0.0"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    Install `author/my-package@1.0.0`

                    Or add to `wally.toml`...
                    MyPackage = "author/my-package@1.0.0"
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const readmeContent = env.ReadFile("README.md")
        -- Both occurrences should be updated.
        const _, count = string.gsub(readmeContent, "author/my%-package@3%.0%.0", "")
        expect(count).to.equal(2)
    end)

    it("should sync fork version to README.md", function()
        env.WriteFile("VERSION", "3.1.1-horse.0.4\n")
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

                    Install `author/my-package@3.1.1-horse.0.3`
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const wallyContent = env.ReadFile("wally.toml")
        expect(string.find(wallyContent, 'version = "3.1.1%-horse.0.4"')).to.be.ok()
        const readmeContent = env.ReadFile("README.md")
        expect(string.find(readmeContent, "author/my%-package@3%.1%.1%-horse%.0%.4")).to.be.ok()
    end)

    it("should sync prerelease version to README.md", function()
        env.WriteFile("VERSION", "2.0.0-beta.6\n")
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

                    Install `author/my-package@2.0.0-beta.5`
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const readmeContent = env.ReadFile("README.md")
        expect(string.find(readmeContent, "author/my%-package@2%.0%.0%-beta%.6")).to.be.ok()
    end)

    it("should preserve punctuation when synchronizing every README reference", function()
        const originalReadme = "Install author/my-package@1.0.0.\nOr `author/my-package@1.0.0-beta.5`...\n"
        for _, version in { "2.0.0", "2.0.0-beta.6", "2.0.0-horse.1.2" } do
            env.WriteFile("VERSION", `{version}\n`)
            env.WriteFile("wally.toml", '[package]\nname = "author/my-package"\nversion = "1.0.0"\n')
            env.WriteFile("README.md", originalReadme)

            const result = env.RunScript("SyncVersion")

            expect(result.ok).to.equal(true)
            expect(env.ReadFile("README.md")).to.equal(
                `Install author/my-package@{version}.\nOr \`author/my-package@{version}\`...\n`
            )
        end
    end)

    it("should reject empty versions before modifying the manifest or README", function()
        const originalManifest = '[package]\nname = "author/my-package"\nversion = "1.0.0"\n'
        const originalReadme = "Install author/my-package@1.0.0.\n"
        for _, version in { "", " \t\n " } do
            env.WriteFile("VERSION", version)
            env.WriteFile("wally.toml", originalManifest)
            env.WriteFile("README.md", originalReadme)

            const result = env.RunScript("SyncVersion")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, 'The "VERSION" file is empty or invalid.', 1, true)).to.be.ok()
            expect(env.ReadFile("wally.toml")).to.equal(originalManifest)
            expect(env.ReadFile("README.md")).to.equal(originalReadme)
        end
    end)

    it("should not modify README.md if no package dependency string exists", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile(
            "wally.toml",
            dedent([[
                    [package]
                    name = "author/my-package"
                    version = "1.0.0"
                ]])
        )
        env.WriteFile(
            "README.md",
            dedent([[
                    # my-package

                    This is a package without installation instructions.
                ]])
        )

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        const readmeContent = env.ReadFile("README.md")
        expect(string.find(readmeContent, "without installation")).to.be.ok()
    end)
end
