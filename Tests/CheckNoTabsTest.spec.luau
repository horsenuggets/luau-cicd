--[[

CheckNoTabsTest.spec

Tests for the CheckNoTabs script.

--]]

const ResolveScanDirectory = require("../Scripts/Helpers/ResolveScanDirectory.func")
const TestEnvironment = require("./Helpers/TestEnvironment")
const process = require("@lune/process")

-- Helper to create content with tabs (using \t escape in regular strings).
const TAB = "\t"

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should pass when file uses spaces for indentation", function()
        env.WriteFile(
            "test.luau",
            [=[--[[

Test

Description here.

--]]

const function foo()
    return "bar"
end

return foo
]=]
        )

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "Validated space-only indentation in 1 file.", 1, true)).to.be.ok()
    end)

    it("should fail when file contains tabs", function()
        const content =
            `--[[\n\nTest\n\nDescription.\n\n--]]\n\nconst function foo()\n{TAB}return "bar"\nend\n\nreturn foo\n`
        env.WriteFile("test.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "file.*with tabs")).to.be.ok()
    end)

    it("should report multiple lines with tabs", function()
        const content =
            `--[[\n\nTest\n\nDescription.\n\n--]]\n\nconst function foo()\n{TAB}const a = 1\n{TAB}const b = 2\n{TAB}return a + b\nend\n\nreturn foo\n`
        env.WriteFile("test.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Tabs appear on lines 10, 11, 12.", 1, true)).to.be.ok()
    end)

    it("should check multiple files", function()
        env.WriteFile(
            "good.luau",
            [=[--[[

Good

Description here.

--]]

return {}
]=]
        )
        const badContent = `--[[\n\nBad\n\nDescription.\n\n--]]\n\nreturn \{\n{TAB}Value = 1\n\}\n`
        env.WriteFile("bad.luau", badContent)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "bad.luau")).to.be.ok()
    end)

    it("should check files in subdirectories", function()
        const content = `--[[\n\nModule\n\nDescription.\n\n--]]\n\nreturn \{\n{TAB}Value = 1\n\}\n`
        env.WriteFile("Source/Module.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "Source/Module.luau")).to.be.ok()
    end)

    it("should skip excluded directories", function()
        const content = `--[[\n\nDep\n\nDescription.\n\n--]]\n\nreturn \{\n{TAB}Value = 1\n\}\n`
        env.WriteFile("DevPackages/dep.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(true)
    end)

    it("should preserve root exclusions for equivalent directory arguments", function()
        for _, folder in { "Build", ".wt/feature/example", ".worktrees/example" } do
            env.WriteFile(`{folder}/Invalid.luau`, `{TAB}return \{\}\n`)
        end

        const cwdResult = process.exec("lune", { "run", "-" }, {
            cwd = env.Path,
            stdio = { stdin = 'print(require("@lune/process").cwd)' },
        })
        expect(cwdResult.ok).to.equal(true)
        const root = string.match(cwdResult.stdout, "^%s*(.-)%s*$") :: string
        for _, directory in { ".", "./", "././", "Build/../", root, `{root}/`, `{root}/./` } do
            const result = env.RunScript("CheckNoTabs", { directory })
            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "0 files", 1, true)).to.be.ok()
        end
    end)

    it("should still validate generated-looking directories below a scanned subfolder", function()
        for _, folder in { "Build", ".wt", ".worktrees" } do
            env.WriteFile(`Source/{folder}/Invalid.luau`, `{TAB}return \{\}\n`)
        end

        for _, directory in { "Source", "./Source/", `{env.Path}/Source/` } do
            const result = env.RunScript("CheckNoTabs", { directory })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "3 files with tabs", 1, true)).to.be.ok()
        end
    end)

    it("should normalize scan paths without mistaking subfolders for roots", function()
        env.WriteDir("Build")
        env.WriteDir("Source/Build")
        const base = ResolveScanDirectory(".", env.Path)
        const cases = {
            { Path = "./", Root = true, Value = base },
            { Path = "Build/../", Root = true, Value = base },
            { Path = "Source/Build/", Root = false, Value = `{base}/Source/Build` },
        }
        if process.os == "windows" then
            table.insert(cases, { Path = ".\\Build\\..\\", Root = true, Value = base })
        end

        for _, case in cases do
            const directory, scanningRepoRoot = ResolveScanDirectory(case.Path, env.Path)
            expect(directory).to.equal(case.Value)
            expect(scanningRepoRoot).to.equal(case.Root)
        end
    end)

    it("should resolve checkout paths with spaces, quotes, and Unicode", function()
        const folder = "Checkout 'quoted' café"
        env.WriteFile(`{folder}/Module.luau`, "--[[\n\nModule\n\nValid module.\n\n--]]\n\nreturn {}\n")
        const checkout = `{env.Path}/{folder}`
        const directory, scanningRepoRoot = ResolveScanDirectory(".", checkout)
        expect(string.sub(directory, -#folder)).to.equal(folder)
        expect(scanningRepoRoot).to.equal(true)

        for _, scriptName in { "CheckFileHeaders", "CheckNoTabs" } do
            const result = process.exec("lune", {
                "run",
                `{process.cwd}/Scripts/{scriptName}.exec.luau`,
            }, { cwd = checkout })
            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, "1 file", 1, true)).to.be.ok()
        end
    end)

    if process.os ~= "windows" then
        it("should scan POSIX source folder names containing backslashes", function()
            for _, folder in { "Build\\Source", "Source\\Packages" } do
                env.WriteFile(`{folder}/Invalid.luau`, "\treturn {}\n")
            end
            for _, scriptName in { "CheckFileHeaders", "CheckNoTabs" } do
                const result = env.RunScript(scriptName)
                expect(result.ok).to.equal(false)
                expect(string.find(result.stdout, "Build\\Source/Invalid.luau", 1, true)).to.be.ok()
                expect(string.find(result.stdout, "Source\\Packages/Invalid.luau", 1, true)).to.be.ok()
            end
        end)

        it("should preserve special characters in POSIX checkout paths", function()
            env.WriteFile("Repo/Invalid.luau", "\treturn {}\n")
            for _, folder in { "Repo\\name", "Repo\n", "Repo\r", "Repo\r\n", "Repo\n\n" } do
                env.WriteFile(`{folder}/Module.luau`, "--[[\n\nModule\n\nValid module.\n\n--]]\n\nreturn {}\n")
                const checkout = `{env.Path}/{folder}`
                const directory, scanningRepoRoot = ResolveScanDirectory(".", checkout)
                expect(string.sub(directory, -#folder)).to.equal(folder)
                expect(scanningRepoRoot).to.equal(true)

                for _, scriptName in { "CheckFileHeaders", "CheckNoTabs" } do
                    const result = process.exec("lune", {
                        "run",
                        `{process.cwd}/Scripts/{scriptName}.exec.luau`,
                    }, { cwd = checkout })
                    expect(result.ok).to.equal(true)
                    expect(string.find(result.stdout, "1 file", 1, true)).to.be.ok()
                end
            end
        end)
    end

    it("should resolve parent directories through symbolic links before scanning", function()
        env.WriteDir("Repository")
        env.WriteDir("External/Child")
        env.WriteFile("External/Build/Bad.luau", "\treturn {}\n")

        const repository = `{env.Path}/Repository`
        const target = `{env.Path}/External/Child`
        const link = `{repository}/Linked`
        const windows = process.os == "windows"
        const command = if windows then "cmd" else "ln"
        const args = if windows then { "/d", "/c", "mklink", "/J", link, target } else { "-s", target, link }
        const linked = process.exec(command, args)
        expect(linked.ok).to.equal(true)

        const _, scanningRepoRoot = ResolveScanDirectory("Linked/..", repository)
        expect(scanningRepoRoot).to.equal(false)

        for _, scriptName in { "CheckFileHeaders", "CheckNoTabs" } do
            const result = process.exec("lune", {
                "run",
                `{process.cwd}/Scripts/{scriptName}.exec.luau`,
                "Linked/..",
            }, { cwd = repository })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stdout, "Build/Bad.luau", 1, true)).to.be.ok()
        end
    end)

    it("should detect tabs anywhere in a line", function()
        const content = `--[[\n\nTest\n\nDescription here.\n\n--]]\n\nconst value = "hello{TAB}world"\n\nreturn value\n`
        env.WriteFile("test.luau", content)

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(false)
        expect(string.find(result.stdout, "with tabs")).to.be.ok()
    end)

    it("should pass when directory has no luau files", function()
        env.WriteFile("readme.md", "# Test\n\nSome content.\n")

        const result = env.RunScript("CheckNoTabs", { env.Path })

        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "0 file")).to.be.ok()
    end)
end
