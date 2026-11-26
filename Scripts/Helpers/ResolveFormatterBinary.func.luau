--[[

ResolveFormatterBinary.func

Selects an explicit formatter binary or the first usable StyLuau/StyLua executable.
The availability probe is injected so selection can be tested independently of PATH.

--]]

const function ResolveFormatterBinary(binary: string?, isAvailable: (string) -> boolean): string?
    assert(binary == nil or type(binary) == "string", "Expected an optional binary string.")
    assert(type(isAvailable) == "function", "Expected an availability probe function.")

    if binary ~= nil then
        assert(binary ~= "", "Expected a nonempty binary string.")
        return binary
    end

    for _, candidate in { "styluau", "stylua" } do
        if isAvailable(candidate) then
            return candidate
        end
    end

    return nil
end

return ResolveFormatterBinary
