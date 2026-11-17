--[[

CreateGitTagTest.spec

Tests for the CreateGitTag script against a real local bare remote, checking that valid
tags reach the remote and malformed ones never touch Git.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

const TestEnvironment = require("./Helpers/TestEnvironment")
const process = require("@lune/process")

return function()
    local env: TestEnvironment.Environment
    local remote: string

    beforeEach(function()
        env = TestEnvironment.create()
        remote = `{env.Path}/.remote.git`
        env.InitGit()
        env.WriteFile("README.md", "Hello.\n")
        env.GitCommit("Initial")
        process.exec("git", { "init", "-q", "--bare", remote })
        process.exec("git", { "remote", "add", "origin", remote }, { cwd = env.Path })
    end)

    afterEach(function()
        env.Cleanup()
    end)

    const function remoteTags(): string
        return process.exec("git", { "tag", "--list" }, { cwd = remote }).stdout
    end

    it("should create and push a valid tag", function()
        const result = env.RunScript("CreateGitTag", { "1.2.3" })
        expect(result.ok).to.equal(true)
        expect(remoteTags()).to.equal("1.2.3\n")
    end)

    it("should create and push a tag with a prerelease suffix", function()
        const result = env.RunScript("CreateGitTag", { "2.0.0-beta.6" })
        expect(result.ok).to.equal(true)
        expect(remoteTags()).to.equal("2.0.0-beta.6\n")
    end)

    it("should fail when the tag already exists", function()
        env.GitTag("1.2.3")
        const result = env.RunScript("CreateGitTag", { "1.2.3" })
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, 'Could not create the tag "1.2.3".', 1, true)).to.be.ok()
    end)

    it("should fail when the push fails", function()
        process.exec("git", { "remote", "set-url", "origin", `{env.Path}/.missing.git` }, { cwd = env.Path })
        const result = env.RunScript("CreateGitTag", { "1.2.3" })
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, 'Could not push the tag "1.2.3"', 1, true)).to.be.ok()
    end)

    for _, tag in { "--help", "v1.2.3", "1.2", "1.2.3\n", "" } do
        it(`should reject {TestEnvironment.quote(tag)} without creating a tag`, function()
            const result = env.RunScript("CreateGitTag", { tag })
            expect(result.ok).to.equal(false)
            expect(string.find(result.stderr, "Invalid release tag", 1, true)).to.be.ok()
            expect(process.exec("git", { "tag", "--list" }, { cwd = env.Path }).stdout).to.equal("")
            expect(remoteTags()).to.equal("")
        end)
    end

    it("should print usage without a tag", function()
        const result = env.RunScript("CreateGitTag")
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
    end)
end
