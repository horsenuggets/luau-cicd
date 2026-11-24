--[[

IsReleaseVersionTest.spec

Tests for the IsReleaseVersion helper, which must reject anything that could smuggle flags
or extra lines into tags, titles, and workflow outputs.

--]]

const Testable = require("@devpackages/Testable")
const expect, it = Testable.expect, Testable.it

const IsReleaseVersion = require("../Scripts/Helpers/IsReleaseVersion.func")
const TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    for _, value in
        {
            "0.0.1",
            "1.2.3",
            "10.20.30",
            "99999.99999.99999",
            "1.2.3-beta",
            "2.0.0-beta.6",
            "3.1.1-horse.0.5",
            "1.70.1-horse.1.11",
            "1.0.0-rc.1",
            "1.0.0-0",
            "1.0.0-x-y-z.--",
            "1.0.0-alpha.0a"
        }
    do
        it(`should accept "{value}"`, function()
            expect(IsReleaseVersion(value)).to.equal(true)
        end)
    end

    for _, value in
        {
            "",
            "1.2",
            "1.2.3.4",
            "v1.2.3",
            "--help",
            " 1.2.3",
            "1.2.3 ",
            "1.2.3\n",
            "1.2.3\ninjected=value",
            "100000.0.0",
            "1.2.3-",
            "1.2.3-beta.",
            "1.2.3-.beta",
            "1.2.3-beta..1",
            "1.2.3-beta.01",
            "1.2.3-00",
            "1.2.3-beta_1",
            "1.2.3-beta 1",
            "1.2.3-beta\n",
            "1.2.3-beta\ninjected=value",
            "1.2.3+build",
            "1.2.3-beta+build",
            "100000.0.0-beta",
            "1.2-beta"
        }
    do
        it(`should reject {TestEnvironment.quote(value)}`, function()
            expect(IsReleaseVersion(value)).to.equal(false)
        end)
    end
end
