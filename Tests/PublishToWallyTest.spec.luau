--[[

PublishToWallyTest.spec

Tests for the PublishToWally script. A stub "wally" on "PATH" records its arguments, and
"HOME" points into the test directory, so nothing is published and no real auth file is
touched.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

const TestEnvironment = require("./Helpers/TestEnvironment")
const process = require("@lune/process")

const AUTH = '[tokens]\n"https://api.wally.run/" = "token"\n'
const PUBLIC_MANIFEST = '[package]\nname = "user/package"\nversion = "1.0.0"\n'

return function()
    local env: TestEnvironment.Environment
    local stubEnv: { [string]: string }

    beforeEach(function()
        env = TestEnvironment.create()
        env.WriteFile("bin/wally", '#!/bin/sh\nprintf "%s\\n" "$@" > "$CALL_LOG"\n')
        process.exec("chmod", { "+x", `{env.Path}/bin/wally` })
        env.WriteDir("home")
        stubEnv = {
            CALL_LOG = `{env.Path}/calls.txt`,
            HOME = `{env.Path}/home`,
            PATH = `{env.Path}/bin:{process.env.PATH}`,
            -- Rokit finds its tools through "HOME" by default, so keep it on the real root.
            ROKIT_ROOT = process.env.ROKIT_ROOT or `{process.env.HOME}/.rokit`,
            WALLY_AUTH = AUTH,
        }
    end)

    afterEach(function()
        env.Cleanup()
    end)

    it("should write the auth file and publish a public package", function()
        env.WriteFile("wally.toml", PUBLIC_MANIFEST)

        const result = env.RunScript("PublishToWally", nil, stubEnv)
        expect(result.ok).to.equal(true)
        expect(env.ReadFile("home/.wally/auth.toml")).to.equal(AUTH)
        expect(env.ReadFile("calls.txt")).to.equal("publish\n")
    end)

    for _, case in
        {
            { Name = "there is no manifest", Manifest = nil, Message = 'No "wally.toml" was found.' },
            {
                Name = "the package is private",
                Manifest = `{PUBLIC_MANIFEST}private = true\n`,
                Message = "A private package was detected.",
            },
        }
    do
        it(`should skip publishing when {case.Name}, even without a secret`, function()
            if case.Manifest then
                env.WriteFile("wally.toml", case.Manifest)
            end
            stubEnv.WALLY_AUTH = ""

            const result = env.RunScript("PublishToWally", nil, stubEnv)
            expect(result.ok).to.equal(true)
            expect(string.find(result.stdout, case.Message, 1, true)).to.be.ok()
            expect(env.FileExists("calls.txt")).to.equal(false)
            expect(env.FileExists("home/.wally/auth.toml")).to.equal(false)
        end)
    end

    it("should fail without calling wally when the secret is missing", function()
        env.WriteFile("wally.toml", PUBLIC_MANIFEST)
        stubEnv.WALLY_AUTH = ""

        const result = env.RunScript("PublishToWally", nil, stubEnv)
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, 'The "WALLY_AUTH" secret is not configured.', 1, true)).to.be.ok()
        expect(env.FileExists("calls.txt")).to.equal(false)
    end)

    it("should fail when wally fails", function()
        env.WriteFile("wally.toml", PUBLIC_MANIFEST)
        env.WriteFile("bin/wally", "#!/bin/sh\nexit 1\n")

        const result = env.RunScript("PublishToWally", nil, stubEnv)
        expect(result.ok).to.equal(false)
        expect(string.find(result.stderr, "Could not publish to Wally.", 1, true)).to.be.ok()
    end)

    it("should never print the secret", function()
        env.WriteFile("wally.toml", PUBLIC_MANIFEST)
        stubEnv.WALLY_AUTH = "super-secret-token"

        const result = env.RunScript("PublishToWally", nil, stubEnv)
        expect(string.find(result.stdout, "super-secret-token", 1, true)).to.equal(nil)
        expect(string.find(result.stderr, "super-secret-token", 1, true)).to.equal(nil)
    end)
end
