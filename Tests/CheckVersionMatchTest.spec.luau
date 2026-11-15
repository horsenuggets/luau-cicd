--[[

CheckVersionMatchTest.spec

Tests for the CheckVersionMatch script.

--]]

const GetReadmeVersionReferences = require("../Scripts/Helpers/GetReadmeVersionReferences.func")
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

    it("should accept every matching README reference and ignore surrounding punctuation", function()
        for _, version in { "2.0.0", "2.0.0-beta.5", "2.0.0-horse.1.2", "2.0.0+build.1", "2.0.0-beta.5+build.1" } do
            env.WriteFile("VERSION", `{version}\n`)
            env.WriteFile("wally.toml", `[package]\nname = "author/my-package"\nversion = "{version}"\n`)
            env.WriteFile(
                "README.md",
                `Install author/my-package@{version}.\nOr use \`author/my-package@{version}\`.\n`
            )

            const result = env.RunScript("CheckVersionMatch")

            expect(result.ok).to.equal(true)
        end
    end)

    it("should reject any stale README reference regardless of its position", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile("wally.toml", '[package]\nname = "author/my-package"\nversion = "2.0.0"\n')
        for _, versions in { { "2.0.0", "1.0.0" }, { "1.0.0", "2.0.0" } } do
            env.WriteFile(
                "README.md",
                `Install author/my-package@{versions[1]}.\nOr author/my-package@{versions[2]}.\n`
            )

            const result = env.RunScript("CheckVersionMatch")

            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "author/my-package@1.0.0", 1, true)).to.be.ok()
        end
    end)

    it("should validate active TOML fields instead of commented assignments", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile("README.md", "author/my-package@2.0.0\nother/package@1.0.0\n")
        for _, manifest in
            {
                '[package]\nname = "author/my-package"\nversion = "1.0.0"\n# version = "2.0.0"\n',
                '[package]\nname = "author/my-package"\n# version = "2.0.0"\n',
            }
        do
            env.WriteFile("wally.toml", manifest)
            expect(env.RunScript("CheckVersionMatch").ok).to.equal(false)
        end
        env.WriteFile(
            "wally.toml",
            '[package]\nname = "author/my-package"\nversion = "2.0.0"\n# name = "other/package"\n'
        )
        expect(env.RunScript("CheckVersionMatch").ok).to.equal(true)
        env.WriteFile("README.md", "author/my-package@1.0.0\nother/package@2.0.0\n")
        expect(env.RunScript("CheckVersionMatch").ok).to.equal(false)
    end)

    it("should accept quoted TOML keys and literal package values", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile("README.md", "author/my-package@2.0.0\n")
        for _, manifest in
            {
                "[\"package\"]\n\"name\" = 'author/my-package'\n'version' = '2.0.0'\n",
                'package = { name = "author/my-package", version = "2.0.0" }\n',
                'package.name = "author/my-package"\npackage.version = "2.0.0"\n',
                'description = \'\'\'\n[package]\nversion = "9.0.0"\nname = "other/package"\n\'\'\'\n[package]\nname = "author/my-package"\nversion = "2.0.0"\n',
            }
        do
            env.WriteFile("wally.toml", manifest)
            expect(env.RunScript("CheckVersionMatch").ok).to.equal(true)
        end
    end)

    it("should compare README build metadata as part of the version", function()
        env.WriteFile("VERSION", "2.0.0+build.2\n")
        env.WriteFile("wally.toml", '[package]\nname = "author/my-package"\nversion = "2.0.0+build.2"\n')
        env.WriteFile("README.md", "Install author/my-package@2.0.0+build.1.\n")

        const result = env.RunScript("CheckVersionMatch")

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "author/my-package@2.0.0+build.1", 1, true)).to.be.ok()
        const content = "Use author/my-package@2.0.0-beta.5+build.1..."
        const references = GetReadmeVersionReferences(content, "author/my-package")
        expect(#references).to.equal(1)
        expect(references[1].Version).to.equal("2.0.0-beta.5+build.1")
        expect(string.sub(content, references[1].Start, references[1].End)).to.equal("2.0.0-beta.5+build.1")
        expect(string.sub(content, references[1].End + 1)).to.equal("...")
    end)

    it("should reject incomplete numeric README versions", function()
        env.WriteFile("VERSION", "2.0.0\n")
        env.WriteFile("wally.toml", '[package]\nname = "author/my-package"\nversion = "2.0.0"\n')
        for _, version in { "1", "1.0" } do
            env.WriteFile("README.md", `Install author/my-package@{version}.\n`)
            const result = env.RunScript("CheckVersionMatch")
            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Version mismatch", 1, true)).to.be.ok()
        end
    end)

    it("should ignore coordinate substrings and version-agnostic references", function()
        for _, prefix in { "other-", "other_", "other.", "other/", "other", "9" } do
            const content = `{prefix}author/my-package@1.0.0 author/my-package@latest`
            expect(#GetReadmeVersionReferences(content, "author/my-package")).to.equal(0)
        end
        for _, prefix in { "", " ", "`", '"', "(" } do
            const content = `{prefix}author/my-package@1.0...`
            const references = GetReadmeVersionReferences(content, "author/my-package")
            expect(#references).to.equal(1)
            expect(references[1].Version).to.equal("1.0")
            expect(string.sub(content, references[1].Start, references[1].End)).to.equal("1.0")
            expect(string.sub(content, references[1].End + 1)).to.equal("...")
        end
    end)

    it("should return exact reference bounds without matching another package", function()
        const content = "Use other/package@1.0.0, author/my-package@2.0.0-beta.5..."
        const references = GetReadmeVersionReferences(content, "author/my-package")
        const repeatedReferences = GetReadmeVersionReferences(content, "author/my-package")

        expect(#references).to.equal(1)
        expect(references[1].Version).to.equal("2.0.0-beta.5")
        expect(string.sub(content, references[1].Start, references[1].End)).to.equal("2.0.0-beta.5")
        expect(string.sub(content, references[1].End + 1)).to.equal("...")
        expect(repeatedReferences[1].Start).to.equal(references[1].Start)
        expect(repeatedReferences[1].End).to.equal(references[1].End)
        expect(repeatedReferences[1].Version).to.equal(references[1].Version)
        expect(#GetReadmeVersionReferences("No dependency references.", "author/my-package")).to.equal(0)
    end)

    it("should reject non-string reference helper arguments", function()
        for _, args in { { false, "author/my-package" }, { "README content", false } } do
            const ok = pcall(function()
                GetReadmeVersionReferences(args[1] :: any, args[2] :: any)
            end)

            expect(ok).to.equal(false)
        end
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
