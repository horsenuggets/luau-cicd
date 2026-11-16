--[[

PackageBinaryTest.spec

Tests for the PackageBinary script on every supported target, checking archive names,
contents, executable bits, stale entry removal, and invalid inputs.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")
const process = require("@lune/process")

const TARGETS = {
    { Target = "linux-x86_64", Suffix = "linux-x64", Binary = "tool" },
    { Target = "linux-aarch64", Suffix = "linux-arm64", Binary = "tool" },
    { Target = "macos-x86_64", Suffix = "macos-x64", Binary = "tool" },
    { Target = "macos-aarch64", Suffix = "macos-arm64", Binary = "tool" },
    { Target = "windows-x86_64", Suffix = "windows-x64", Binary = "tool.exe" },
    { Target = "windows-aarch64", Suffix = "windows-arm64", Binary = "tool.exe" },
}

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    const function entries(archivePath: string): string
        return process.exec("unzip", { "-Z1", archivePath }, { cwd = env.Path }).stdout
    end

    for _, case in TARGETS do
        it(`should package "{case.Target}" as "tool-{case.Suffix}.zip"`, function()
            env.WriteFile(`Build/{case.Binary}`, "binary\n")

            const result = env.RunScript("PackageBinary", { "tool", case.Target }, {
                GITHUB_OUTPUT = `{env.Path}/github-output`,
            })
            expect(result.ok).to.equal(true)

            const archivePath = `Build/tool-{case.Suffix}.zip`
            expect(entries(archivePath)).to.equal(`{case.Binary}\n`)
            expect(env.ReadFile("github-output")).to.equal(`archive={archivePath}\n`)

            process.exec("unzip", { "-q", archivePath, "-d", "extracted" }, { cwd = env.Path })
            expect(env.ReadFile(`extracted/{case.Binary}`)).to.equal("binary\n")
            expect(process.exec("test", { "-x", `{env.Path}/extracted/{case.Binary}` }).ok).to.equal(true)
        end)
    end

    it("should replace an archive with stale entries", function()
        env.WriteFile("Build/tool", "binary\n")
        env.WriteFile("Build/stale.txt", "stale\n")
        process.exec("zip", { "-q", "tool-linux-x64.zip", "stale.txt" }, { cwd = `{env.Path}/Build` })

        expect(env.RunScript("PackageBinary", { "tool", "linux-x86_64" }).ok).to.equal(true)
        expect(entries("Build/tool-linux-x64.zip")).to.equal("tool\n")
    end)

    it("should skip the output when GITHUB_OUTPUT is not set", function()
        env.WriteFile("Build/tool", "binary\n")
        expect(env.RunScript("PackageBinary", { "tool", "linux-x86_64" }, { GITHUB_OUTPUT = "" }).ok).to.equal(true)
        expect(env.FileExists("github-output")).to.equal(false)
    end)

    for _, case in
        {
            { Name = "missing", Target = "linux-x86_64", Setup = nil },
            { Name = "empty", Target = "linux-x86_64", Setup = "" },
            { Name = "missing for Windows", Target = "windows-x86_64", Setup = nil },
        }
    do
        it(`should fail when the executable is {case.Name}`, function()
            if case.Setup then
                env.WriteFile("Build/tool", case.Setup)
            end
            const result = env.RunScript("PackageBinary", { "tool", case.Target })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, "Missing or empty executable", 1, true)).to.be.ok()
        end)
    end

    for _, target in { "../../escape", "linux", "freebsd-x64", "x86_64-unknown-linux-gnu" } do
        it(`should reject the target "{target}"`, function()
            env.WriteFile("Build/tool", "binary\n")
            const result = env.RunScript("PackageBinary", { "tool", target })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, "Unsupported release", 1, true)).to.be.ok()
        end)
    end

    for _, name in { "../tool", "", "-tool", "tool name" } do
        it(`should reject the name {TestEnvironment.quote(name)}`, function()
            const result = env.RunScript("PackageBinary", { name, "linux-x86_64" })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, "Invalid binary name", 1, true)).to.be.ok()
        end)
    end

    it("should print usage with the wrong number of arguments", function()
        const result = env.RunScript("PackageBinary", { "tool" })
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
    end)
end
