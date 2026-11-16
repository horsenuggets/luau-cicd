--[[

CreateGitHubReleaseTest.spec

Tests for the CreateGitHubRelease script. A stub "gh" on "PATH" records its arguments, so
the exact release command is checked without contacting GitHub.

--]]

const TestEnvironment = require("./Helpers/TestEnvironment")
const process = require("@lune/process")

const BASE_CALL = "release\ncreate\n1.2.3\n--verify-tag\n--title\n1.2.3\n--notes-file\nnotes.txt\n--\n"

return function()
    local env: TestEnvironment.Environment
    local stubEnv: { [string]: string }

    beforeEach(function()
        env = TestEnvironment.create()
        env.WriteFile("bin/gh", '#!/bin/sh\nprintf "%s\\n" "$@" > "$CALL_LOG"\n')
        process.exec("chmod", { "+x", `{env.Path}/bin/gh` })
        env.WriteFile("notes.txt", "- Notes.\n")
        stubEnv = {
            CALL_LOG = `{env.Path}/calls.txt`,
            PATH = `{env.Path}/bin:{process.env.PATH}`,
        }
    end)

    afterEach(function()
        env.Cleanup()
    end)

    const function writeZip(relativePath: string)
        env.WriteFile("payload.txt", "binary\n")
        const dir = string.match(relativePath, "^(.*)/[^/]+$")
        if dir then
            env.WriteDir(dir)
        end
        process.exec("zip", { "-q", `./{relativePath}`, "payload.txt" }, { cwd = env.Path })
    end

    it("should create a release without assets", function()
        const result = env.RunScript("CreateGitHubRelease", { "1.2.3", "notes.txt" }, stubEnv)
        expect(result.ok).to.equal(true)
        expect(env.ReadFile("calls.txt")).to.equal(BASE_CALL)
        expect(string.find(result.stdout, "with 0 assets", 1, true)).to.be.ok()
    end)

    it("should pass assets named like flags as assets", function()
        writeZip("--draft.zip")
        env.WriteFile("--prerelease", "text\n")

        const result =
            env.RunScript("CreateGitHubRelease", { "1.2.3", "notes.txt", "--draft.zip", "--prerelease" }, stubEnv)
        expect(result.ok).to.equal(true)
        expect(env.ReadFile("calls.txt")).to.equal(`{BASE_CALL}--draft.zip\n--prerelease\n`)
    end)

    it("should pass every asset to gh in order", function()
        writeZip("artifacts/tool-linux-x64.zip")
        writeZip("artifacts/tool-macos-arm64.zip")
        env.WriteFile("artifacts/checksums.txt", "abc\n")

        const result = env.RunScript("CreateGitHubRelease", {
            "1.2.3",
            "notes.txt",
            "artifacts/tool-linux-x64.zip",
            "artifacts/tool-macos-arm64.zip",
            "artifacts/checksums.txt",
        }, stubEnv)
        expect(result.ok).to.equal(true)
        const assetLines = "artifacts/tool-linux-x64.zip\nartifacts/tool-macos-arm64.zip\nartifacts/checksums.txt\n"
        expect(env.ReadFile("calls.txt")).to.equal(`{BASE_CALL}{assetLines}`)
        expect(string.find(result.stdout, "with 3 assets", 1, true)).to.be.ok()
    end)

    it("should use the singular for one asset", function()
        writeZip("tool.zip")
        const result = env.RunScript("CreateGitHubRelease", { "1.2.3", "notes.txt", "tool.zip" }, stubEnv)
        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "with 1 asset.", 1, true)).to.be.ok()
    end)

    for _, case in
        {
            { Name = "missing", Setup = function() end, Message = "Missing or empty release asset" },
            {
                Name = "empty",
                Setup = function()
                    env.WriteFile("tool.zip", "")
                end,
                Message = "Missing or empty release asset",
            },
            {
                Name = "corrupt",
                Setup = function()
                    env.WriteFile("tool.zip", "not an archive\n")
                end,
                Message = "is not a valid ZIP archive",
            },
        }
    do
        it(`should fail without calling gh when an asset is {case.Name}`, function()
            case.Setup()
            const result = env.RunScript("CreateGitHubRelease", { "1.2.3", "notes.txt", "tool.zip" }, stubEnv)
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, case.Message, 1, true)).to.be.ok()
            expect(env.FileExists("calls.txt")).to.equal(false)
        end)
    end

    it("should fail without calling gh when the notes are empty", function()
        env.WriteFile("notes.txt", "")
        const result = env.RunScript("CreateGitHubRelease", { "1.2.3", "notes.txt" }, stubEnv)
        expect(result.ok).to.equal(false)
        expect(env.FileExists("calls.txt")).to.equal(false)
    end)

    for _, tag in { "--help", "v1.2.3", "1.2.3\n" } do
        it(`should reject the tag {TestEnvironment.quote(tag)} without calling gh`, function()
            const result = env.RunScript("CreateGitHubRelease", { tag, "notes.txt" }, stubEnv)
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, "Invalid release tag", 1, true)).to.be.ok()
            expect(env.FileExists("calls.txt")).to.equal(false)
        end)
    end

    it("should fail when gh fails", function()
        env.WriteFile("bin/gh", "#!/bin/sh\nexit 1\n")
        const result = env.RunScript("CreateGitHubRelease", { "1.2.3", "notes.txt" }, stubEnv)
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, 'Could not create the GitHub release "1.2.3".', 1, true)).to.be.ok()
    end)

    it("should print usage with too few arguments", function()
        const result = env.RunScript("CreateGitHubRelease", { "1.2.3" }, stubEnv)
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
    end)
end
