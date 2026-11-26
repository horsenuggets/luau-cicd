--[[

ResolveFormatterBinaryTest.spec

Tests formatter preference, availability combinations, and explicit overrides without
relying on installed executables.

--]]

const ResolveFormatterBinary = require("../Scripts/Helpers/ResolveFormatterBinary.func")
const Testable = require("@devpackages/Testable")
const expect, it = Testable.expect, Testable.it

return function()
    it("should select the preferred available formatter for every availability combination", function()
        for _, styluau in { false, true } do
            for _, stylua in { false, true } do
                const function probe(binary: string): boolean
                    return if binary == "styluau" then styluau else stylua
                end
                const expected = if styluau then "styluau" elseif stylua then "stylua" else nil
                expect(ResolveFormatterBinary(nil, probe)).to.equal(expected)
                expect(ResolveFormatterBinary(nil, probe)).to.equal(expected)
            end
        end
    end)

    it("should not probe when an explicit binary is supplied", function()
        for _, binary in { "stylua", "styluau", "custom-formatter", "./path with spaces/formatter" } do
            expect(ResolveFormatterBinary(binary, function(): boolean
                error("Explicit selection must not probe other executables.")
            end)).to.equal(binary)
        end
    end)

    it("should stop probing after finding the preferred formatter", function()
        expect(ResolveFormatterBinary(nil, function(binary: string): boolean
            expect(binary).to.equal("styluau")
            return true
        end)).to.equal("styluau")
    end)

    it("should reject an empty explicit binary", function()
        expect(function()
            ResolveFormatterBinary("", function(): boolean
                return true
            end)
        end).to.throw()
    end)
end
