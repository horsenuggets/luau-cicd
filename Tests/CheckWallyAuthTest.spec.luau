--[[

CheckWallyAuthTest.spec

Tests for the CheckWallyAuth script across every combination of manifest presence,
package privacy, and secret presence.

--]]

const Testable = require("@devpackages/Testable")
const afterEach, beforeEach, expect, it = Testable.afterEach, Testable.beforeEach, Testable.expect, Testable.it

const TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    local env: TestEnvironment.Environment

    beforeEach(function()
        env = TestEnvironment.create()
    end)

    afterEach(function()
        env.Cleanup()
    end)

    for _, hasManifest in { false, true } do
        for _, isPrivate in { false, true } do
            for _, hasSecret in { false, true } do
                const expectedOk = not hasManifest or isPrivate or hasSecret
                const label = `manifest={hasManifest}, private={isPrivate}, secret={hasSecret}`

                it(`should {if expectedOk then "pass" else "fail"} with {label}`, function()
                    if hasManifest then
                        env.WriteFile(
                            "wally.toml",
                            `[package]\nname = "user/package"\nversion = "1.0.0"\nprivate = {isPrivate}\n`
                        )
                    end

                    const result = env.RunScript("CheckWallyAuth", nil, {
                        WALLY_AUTH = if hasSecret then '[tokens]\n"api.wally.run" = "token"\n' else "",
                    })
                    expect(result.ok).to.equal(expectedOk)

                    if not expectedOk then
                        expect(string.find(result.stderr, 'The "WALLY_AUTH" secret is not configured.', 1, true)).to.be.ok()
                    end
                end)
            end
        end
    end

    it("should treat a whitespace-only secret as missing", function()
        env.WriteFile("wally.toml", '[package]\nname = "user/package"\nversion = "1.0.0"\n')
        const result = env.RunScript("CheckWallyAuth", nil, { WALLY_AUTH = "  \n" })
        expect(result.ok).to.equal(false)
    end)

    it("should never print the secret", function()
        env.WriteFile("wally.toml", '[package]\nname = "user/package"\nversion = "1.0.0"\n')
        const result = env.RunScript("CheckWallyAuth", nil, { WALLY_AUTH = "super-secret-token" })
        expect(result.ok).to.equal(true)
        expect(string.find(result.stdout, "super-secret-token", 1, true)).to.equal(nil)
        expect(string.find(result.stderr, "super-secret-token", 1, true)).to.equal(nil)
    end)
end
