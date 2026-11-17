--[[

CheckDiffWithMainTest.spec

Tests for the CheckDiffWithMain script against a real local bare remote, so tree equality
and binary changes are checked exactly as Git reports them.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

const TestEnvironment = require("./Helpers/TestEnvironment")
const process = require("@lune/process")

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
        env.InitGit()
        process.exec("git", { "checkout", "-q", "-b", "main" }, { cwd = env.Path })
        env.WriteFile("tracked.txt", "original\n")
        env.GitCommit("Initial")
        process.exec("git", { "init", "-q", "--bare", `{env.Path}/.remote.git` })
        process.exec("git", { "remote", "add", "origin", `{env.Path}/.remote.git` }, { cwd = env.Path })
        process.exec("git", { "push", "-q", "origin", "main" }, { cwd = env.Path })
        -- Keep the remote out of the working tree that later commits stage.
        env.WriteFile(".git/info/exclude", ".remote.git/\n")
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should pass when HEAD matches main", function()
        const result = env.RunScript("CheckDiffWithMain")
        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "PR branch matches main exactly.", 1, true)).to.be.ok()
    end)

    it("should pass when only the commit differs but the tree matches", function()
        process.exec("git", { "commit", "-q", "--allow-empty", "-m", "Empty" }, { cwd = env.Path })
        const result = env.RunScript("CheckDiffWithMain")
        expect(result.ok).to.equal(true)
    end)

    it("should fail when a text file differs", function()
        env.WriteFile("tracked.txt", "changed\n")
        env.GitCommit("Change")
        const result = env.RunScript("CheckDiffWithMain")
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "must contain exactly what is in main", 1, true)).to.be.ok()
    end)

    it("should fail when a binary file is added", function()
        env.WriteFile("binary.dat", "\0\1\2")
        env.GitCommit("Binary")
        const result = env.RunScript("CheckDiffWithMain")
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "must contain exactly what is in main", 1, true)).to.be.ok()
    end)

    it("should fail when the remote cannot be fetched", function()
        process.exec("git", { "remote", "set-url", "origin", `{env.Path}/.missing.git` }, { cwd = env.Path })
        const result = env.RunScript("CheckDiffWithMain")
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, 'Could not fetch "main" from "origin".', 1, true)).to.be.ok()
    end)

    it("should print usage when given arguments", function()
        const result = env.RunScript("CheckDiffWithMain", { "extra" })
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "[Usage]", 1, true)).to.be.ok()
    end)
end
