--[[

GetWallyPublishSkipReason.func

Decides whether a release should skip publishing to Wally. Returns a complete sentence
explaining why when there is no "wally.toml" or the package is private, or nil when the
package should be published.

--]]

const fs = require("@lune/fs")
const serde = require("@lune/serde")

const function GetWallyPublishSkipReason(manifestPath: string?): string?
    assert(manifestPath == nil or type(manifestPath) == "string", "Expected an optional string for the manifest path.")

    const path = manifestPath or "wally.toml"
    if not fs.isFile(path) then
        return `No "{path}" was found.`
    end

    const packageData = serde.decode("toml", fs.readFile(path)).package
    if type(packageData) == "table" and packageData.private == true then
        return "A private package was detected."
    end

    return nil
end

return GetWallyPublishSkipReason
