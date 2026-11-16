--[[

IsReleaseVersionTest.spec

Tests for the IsReleaseVersion helper, which must reject anything that could smuggle flags
or extra lines into tags, titles, and workflow outputs.

--]]

const IsReleaseVersion = require("../Scripts/Helpers/IsReleaseVersion.func")
const TestEnvironment = require("./Helpers/TestEnvironment")

return function()
    for _, value in { "0.0.1", "1.2.3", "10.20.30", "99999.99999.99999" } do
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
            "1.2.3-beta",
            "100000.0.0",
        }
    do
        it(`should reject {TestEnvironment.quote(value)}`, function()
            expect(IsReleaseVersion(value)).to.equal(false)
        end)
    end
end
