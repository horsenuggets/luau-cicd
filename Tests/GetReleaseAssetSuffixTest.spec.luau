--[[

GetReleaseAssetSuffixTest.spec

Tests the shared shell release asset suffix contract for every supported platform.

--]]

const process = require("@lune/process")

const SCRIPT_PATH = `{process.cwd}/Scripts/GetReleaseAssetSuffix.sh`

return function()
    it("should run directly as an executable Bash script", function()
        const result = process.exec(SCRIPT_PATH, { "linux-x86_64" })
        expect(result.ok).to.equal(true)
        expect(result.stdout).to.equal("linux-x64\n")
        expect(result.stderr).to.equal("")
    end)

    for _, osName in { "linux", "macos", "windows" } do
        for _, case in
            {
                { Alias = "x86_64", Canonical = "x64" },
                { Alias = "x64", Canonical = "x64" },
                { Alias = "aarch64", Canonical = "arm64" },
                { Alias = "arm64", Canonical = "arm64" },
            }
        do
            const platform = `{osName}-{case.Alias}`
            it(`should normalize "{platform}" without extra output`, function()
                const result = process.exec("bash", { SCRIPT_PATH, platform })
                expect(result.ok).to.equal(true)
                expect(result.stdout).to.equal(`{osName}-{case.Canonical}\n`)
                expect(result.stderr).to.equal("")
            end)
        end
    end

    for _, args in { {}, { "linux-x64", "macos-arm64" }, { "linux-x64", "", "" } } do
        it(`should reject {#args} arguments with usage on stderr`, function()
            const result = process.exec("bash", { SCRIPT_PATH, table.unpack(args) })
            expect(result.ok).to.equal(false)
            expect(result.stdout).to.equal("")
            expect(string.find(result.stderr, "Expected exactly one release platform argument.", 1, true)).to.be.ok()
            expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
        end)
    end

    for _, platform in
        {
            "",
            "-x64",
            "darwin-x64",
            "freebsd-arm64",
            "Linux-x64",
            "ubuntu-x86_64",
            "x86_64-unknown-linux-gnu",
        }
    do
        it(`should reject the operating system in "{platform}"`, function()
            const result = process.exec("bash", { SCRIPT_PATH, platform })
            expect(result.ok).to.equal(false)
            expect(result.stdout).to.equal("")
            expect(string.find(result.stderr, "Unsupported release operating system", 1, true)).to.be.ok()
        end)
    end

    for _, platform in
        {
            "linux",
            "linux-",
            "linux--x64",
            "linux-amd64",
            "linux-x86",
            "linux-x86_64-unknown-linux-gnu",
            "macos-ARM64",
            "macos-arm64 ",
            "windows-arm",
            "windows-x64-extra",
            "windows-x64\n",
        }
    do
        it(`should reject the architecture in "{platform}"`, function()
            const result = process.exec("bash", { SCRIPT_PATH, platform })
            expect(result.ok).to.equal(false)
            expect(result.stdout).to.equal("")
            expect(string.find(result.stderr, "Unsupported release architecture", 1, true)).to.be.ok()
        end)
    end
end
