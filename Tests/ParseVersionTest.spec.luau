--[[

ParseVersionTest.spec

Tests for the parseVersion helper function.

--]]

const parseVersion = require("../Scripts/Helpers/parseVersion")

return function()
    describe("parseVersion", function()
        it("should parse a valid version string", function()
            const major, minor, patch = parseVersion("1.2.3")
            expect(major).to.equal(1)
            expect(minor).to.equal(2)
            expect(patch).to.equal(3)
        end)

        it("should parse version with leading/trailing whitespace", function()
            const major, minor, patch = parseVersion("  1.0.0  ")
            expect(major).to.equal(1)
            expect(minor).to.equal(0)
            expect(patch).to.equal(0)
        end)

        it("should parse version with newline", function()
            const major, minor, patch = parseVersion("2.5.10\n")
            expect(major).to.equal(2)
            expect(minor).to.equal(5)
            expect(patch).to.equal(10)
        end)

        it("should return nil for invalid version string", function()
            const major, minor, patch = parseVersion("not-a-version")
            expect(major).to.equal(nil)
            expect(minor).to.equal(nil)
            expect(patch).to.equal(nil)
        end)

        it("should return nil for partial version", function()
            const major, minor, patch = parseVersion("1.2")
            expect(major).to.equal(nil)
            expect(minor).to.equal(nil)
            expect(patch).to.equal(nil)
        end)

        it("should return nil for version with v prefix", function()
            const major, minor, patch = parseVersion("v1.0.0")
            expect(major).to.equal(nil)
            expect(minor).to.equal(nil)
            expect(patch).to.equal(nil)
        end)

        it("should handle zero version", function()
            const major, minor, patch = parseVersion("0.0.0")
            expect(major).to.equal(0)
            expect(minor).to.equal(0)
            expect(patch).to.equal(0)
        end)
    end)
end
