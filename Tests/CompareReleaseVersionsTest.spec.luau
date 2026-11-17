--[[

CompareReleaseVersionsTest.spec

Tests for the CompareReleaseVersions helper against the SemVer precedence rules, checking
every pair in an ordered chain so the ordering is consistent in both directions.

--]]

const Testable = require("@devpackages/Testable")
const expect, it = Testable.expect, Testable.it

const CompareReleaseVersions = require("../Scripts/Helpers/CompareReleaseVersions.func")

-- Ordered from lowest to highest precedence, including the example from the SemVer spec.
const ORDERED = {
    "0.9.9",
    "1.0.0-0",
    "1.0.0-alpha",
    "1.0.0-alpha.1",
    "1.0.0-alpha.beta",
    "1.0.0-beta",
    "1.0.0-beta.2",
    "1.0.0-beta.11",
    "1.0.0-rc.1",
    "1.0.0",
    "1.0.1-horse.1.6",
    "1.0.1-horse.1.7",
    "1.0.1",
    "1.1.0",
    "2.0.0",
    "10.0.0",
}

return function()
    it("should order every pair in the chain consistently", function()
        for i, a in ORDERED do
            for j, b in ORDERED do
                const expected = if i < j then -1 elseif i > j then 1 else 0
                expect(CompareReleaseVersions(a, b)).to.equal(expected)
            end
        end
    end)

    it("should compare numeric identifiers beyond double precision exactly", function()
        expect(CompareReleaseVersions("1.0.0-beta.9007199254740992", "1.0.0-beta.9007199254740993")).to.equal(-1)
        expect(CompareReleaseVersions("1.0.0-beta.99999999999999999999", "1.0.0-beta.100000000000000000000")).to.equal(
            -1
        )
    end)

    it("should return the same result for the same input", function()
        expect(CompareReleaseVersions("1.0.0-beta.2", "1.0.0-beta.11")).to.equal(
            CompareReleaseVersions("1.0.0-beta.2", "1.0.0-beta.11")
        )
    end)

    for _, args in { { "v1.0.0", "1.0.0" }, { "1.0.0", "1.0" }, { "1.0.0+build", "1.0.0" } } do
        it(`should reject "{args[1]}" and "{args[2]}"`, function()
            expect(function()
                CompareReleaseVersions(args[1], args[2])
            end).to.throw()
        end)
    end
end
