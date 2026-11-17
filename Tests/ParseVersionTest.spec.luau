--[[

ParseVersionTest.spec

Tests for the ParseVersion helper function.

--]]

const Testable = require("@devpackages/Testable")
const expect, it = Testable.expect, Testable.it

const ParseVersion = require("../Scripts/Helpers/ParseVersion.func")

return function()
    it("should reject non-string input", function()
        const ok = pcall(function()
            ParseVersion(123 :: any)
        end)
        expect(ok).to.equal(false)
    end)

    it("should parse a valid version string", function()
        const major, minor, patch = ParseVersion("1.2.3")
        expect(major).to.equal(1)
        expect(minor).to.equal(2)
        expect(patch).to.equal(3)
    end)

    it("should parse version with leading/trailing whitespace", function()
        const major, minor, patch = ParseVersion("  1.0.0  ")
        expect(major).to.equal(1)
        expect(minor).to.equal(0)
        expect(patch).to.equal(0)
    end)

    it("should parse version with newline", function()
        const major, minor, patch = ParseVersion("2.5.10\n")
        expect(major).to.equal(2)
        expect(minor).to.equal(5)
        expect(patch).to.equal(10)
    end)

    it("should return nil for invalid version string", function()
        const major, minor, patch = ParseVersion("not-a-version")
        expect(major).to.equal(nil)
        expect(minor).to.equal(nil)
        expect(patch).to.equal(nil)
    end)

    it("should return nil for partial version", function()
        const major, minor, patch = ParseVersion("1.2")
        expect(major).to.equal(nil)
        expect(minor).to.equal(nil)
        expect(patch).to.equal(nil)
    end)

    it("should return nil for version with v prefix", function()
        const major, minor, patch = ParseVersion("v1.0.0")
        expect(major).to.equal(nil)
        expect(minor).to.equal(nil)
        expect(patch).to.equal(nil)
    end)

    it("should handle zero version", function()
        const major, minor, patch = ParseVersion("0.0.0")
        expect(major).to.equal(0)
        expect(minor).to.equal(0)
        expect(patch).to.equal(0)
    end)
end
