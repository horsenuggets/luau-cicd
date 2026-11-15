--[[

SyncVersionTest.spec

Tests for the SyncVersion script.

--]]

const ReplaceWallyPackageVersion = require("../Scripts/Helpers/ReplaceWallyPackageVersion.func")
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

    it("should repair incomplete versions without modifying another coordinate", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile("wally.toml", '[package]\nname = "author/my-package"\nversion = "1.0.0"\n')
        env.WriteFile("README.md", "author/my-package@1.0. other-author/my-package@1.0.0 author/my-package@latest\n")

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(true)
        expect(env.ReadFile("README.md")).to.equal(
            "author/my-package@2.0.0. other-author/my-package@1.0.0 author/my-package@latest\n"
        )
    end)

    it("should replace complete README build metadata without retaining old suffixes", function()
        for _, version in { "2.0.0", "2.0.0+build.2", "2.0.0-beta.6+build.2" } do
            env.WriteFile("VERSION", `{version}\n`)
            env.WriteFile("wally.toml", '[package]\nname = "author/my-package"\nversion = "1.0.0+build.1"\n')
            env.WriteFile("README.md", "Install author/my-package@1.0.0+build.1.\n")

            const result = env.RunScript("SyncVersion")

            expect(result.ok).to.equal(true)
            expect(env.ReadFile("README.md")).to.equal(`Install author/my-package@{version}.\n`)
            expect(env.ReadFile("wally.toml")).to.equal(
                `[package]\nname = "author/my-package"\nversion = "{version}"\n`
            )
        end
    end)

    it("should replace only the active TOML version token and preserve all other bytes", function()
        const cases = {
            {
                Prefix = '# version = "1.0.0"\n[package]\nname = "author/my-package"\nversion = ',
                Suffix = ' # Keep this.\n# version = "1.0.0"\n# name = "other/package"\n[dependencies]\nOther = "other/package@1.0.0"\n',
                Token = '"1.0.0"',
            },
            {
                Prefix = "[\"package\"]\r\n'name' = 'author/my-package'\r\n\"version\" = ",
                Suffix = '\r\n# version = "1.0.0"\r\n',
                Token = "'1.0.0'",
            },
            {
                Prefix = 'package = { name = "author/my-package", version = ',
                Suffix = ', description = "1.0.0" }\n',
                Token = '"1.0.0"',
            },
            {
                Prefix = 'package.name = "author/my-package"\npackage.version = ',
                Suffix = '\n[metadata]\nversion = "1.0.0"\n',
                Token = '"1.0.\\u0030"',
            },
            {
                Prefix = "description = '''\n[package]\nversion = \"1.0.0\"\nname = \"other/package\"\n'''\n[package]\nname = \"author/my-package\"\nversion = ",
                Suffix = '\n# version = "1.0.0"\n',
                Token = '"1.0.0"',
            },
        }
        for _, case in cases do
            env.WriteFile("VERSION", "2.0.0\n")
            env.WriteFile("wally.toml", `{case.Prefix}{case.Token}{case.Suffix}`)
            env.WriteFile("README.md", "author/my-package@1.0.0 other/package@1.0.0\n")
            const result = env.RunScript("SyncVersion")
            expect(result.ok).to.equal(true)
            expect(env.ReadFile("wally.toml")).to.equal(`{case.Prefix}"2.0.0"{case.Suffix}`)
            expect(env.ReadFile("README.md")).to.equal("author/my-package@2.0.0 other/package@1.0.0\n")
        end
    end)

    it("should locate the same active version token deterministically", function()
        const content = '[metadata]\nversion = "1.0.0"\n[package]\nversion = "1.0.0" # Preserve.\n'
        const expected = '[metadata]\nversion = "1.0.0"\n[package]\nversion = "2.0.0" # Preserve.\n'
        expect(ReplaceWallyPackageVersion(content, "1.0.0", "2.0.0")).to.equal(expected)
        expect(ReplaceWallyPackageVersion(content, "1.0.0", "2.0.0")).to.equal(expected)
        for _, args in { { false, "1.0.0", "2.0.0" }, { content, false, "2.0.0" }, { content, "1.0.0", false } } do
            expect(pcall(function()
                ReplaceWallyPackageVersion(args[1] :: any, args[2] :: any, args[3] :: any)
            end)).to.equal(false)
        end
    end)

    it("should reject comment-only package versions without modifying files", function()
        const manifest = '[package]\nname = "author/my-package"\n# version = "1.0.0"\n'
        const readme = "author/my-package@1.0.0\n"
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile("wally.toml", manifest)
        env.WriteFile("README.md", readme)
        expect(env.RunScript("SyncVersion").ok).to.equal(false)
        expect(env.ReadFile("wally.toml")).to.equal(manifest)
        expect(env.ReadFile("README.md")).to.equal(readme)
    end)

    it("should reject a missing package version before modifying either file", function()
        const originalManifest =
            '[package]\nname = "author/my-package"\n\n[dependencies]\nversion = "other/package@1.0.0"\n'
        const originalReadme = "Install author/my-package@1.0.0.\n"
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile("wally.toml", originalManifest)
        env.WriteFile("README.md", originalReadme)

        const result = env.RunScript("SyncVersion")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, 'Could not find the package version in "wally.toml".', 1, true)).to.be.ok()
        expect(env.ReadFile("wally.toml")).to.equal(originalManifest)
        expect(env.ReadFile("README.md")).to.equal(originalReadme)
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
