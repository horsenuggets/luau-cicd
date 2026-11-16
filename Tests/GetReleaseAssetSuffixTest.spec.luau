--[[

GetReleaseAssetSuffixTest.spec

Tests the release asset suffix contract for every supported platform, both through the
helper function and through the executable script's stdout and stderr.

--]]

const GetReleaseAssetSuffix = require("../Scripts/Helpers/GetReleaseAssetSuffix.func")
const TestEnvironment = require("./Helpers/TestEnvironment")

const INVALID_ARCHITECTURES = {
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
const INVALID_OPERATING_SYSTEMS = {
    "",
    "-x64",
    "darwin-x64",
    "freebsd-arm64",
    "Linux-x64",
    "ubuntu-x86_64",
    "x86_64-unknown-linux-gnu",
}

return function()
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
            it(`should normalize "{platform}"`, function()
                const suffix, suffixError = GetReleaseAssetSuffix(platform)
                expect(suffix).to.equal(`{osName}-{case.Canonical}`)
                expect(suffixError).to.equal(nil)
            end)
        end
    end

    for _, platform in INVALID_OPERATING_SYSTEMS do
        it(`should reject the operating system in {TestEnvironment.quote(platform)}`, function()
            const suffix, suffixError = GetReleaseAssetSuffix(platform)
            expect(suffix).to.equal(nil)
            expect(string.find(suffixError :: string, "Unsupported release operating system", 1, true)).to.be.ok()
        end)
    end

    for _, platform in INVALID_ARCHITECTURES do
        it(`should reject the architecture in {TestEnvironment.quote(platform)}`, function()
            const suffix, suffixError = GetReleaseAssetSuffix(platform)
            expect(suffix).to.equal(nil)
            expect(string.find(suffixError :: string, "Unsupported release architecture", 1, true)).to.be.ok()
        end)
    end

    it("should return the same result for the same input", function()
        expect(GetReleaseAssetSuffix("linux-x86_64")).to.equal(GetReleaseAssetSuffix("linux-x86_64"))
    end)

    describe("the executable script", function()
        local env: TestEnvironment.Environment

        beforeEach(function()
            env = TestEnvironment.create()
        end)

        afterEach(function()
            env.Cleanup()
        end)

        it("should print exactly the suffix on success", function()
            const result = env.RunScript("GetReleaseAssetSuffix", { "linux-x86_64" })
            expect(result.ok).to.equal(true)
            expect(result.stdout).to.equal("linux-x64\n")
            expect(result.stderr).to.equal("")
        end)

        it("should leave stdout empty on failure", function()
            const result = env.RunScript("GetReleaseAssetSuffix", { "darwin-x64" })
            expect(result.ok).to.equal(false)
            expect(result.stdout).to.equal("")
            expect(string.find(result.stderr, "Unsupported release operating system", 1, true)).to.be.ok()
        end)

        for _, args in { {}, { "linux-x64", "macos-arm64" } } do
            it(`should print usage for {#args} arguments`, function()
                const result = env.RunScript("GetReleaseAssetSuffix", args)
                expect(result.ok).to.equal(false)
                expect(result.stdout).to.equal("")
                expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
            end)
        end
    end)
end
