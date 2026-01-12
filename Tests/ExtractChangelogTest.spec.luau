--[[

ExtractChangelogTest

Tests for the extractChangelog helper function.

--]]

local fs = require("@lune/fs")

local extractChangelog = require("../Scripts/Helpers/extractChangelog")

return function()
    describe("extractChangelog", function()
        local originalChangelog: string?

        beforeAll(function()
            if fs.isFile("CHANGELOG.md") then
                originalChangelog = fs.readFile("CHANGELOG.md")
            end
        end)

        afterAll(function()
            if originalChangelog then
                fs.writeFile("CHANGELOG.md", originalChangelog)
            end
        end)

        it("should extract changelog section for existing version", function()
            fs.writeFile(
                "CHANGELOG.md",
                [[# Changelog

## 1.0.0

### Added

- Feature one
- Feature two

## 0.9.0

### Fixed

- Bug fix
]]
            )

            local section = extractChangelog("1.0.0")
            expect(section).to.be.ok()
            expect(string.find(section :: string, "Feature one")).to.be.ok()
            expect(string.find(section :: string, "Feature two")).to.be.ok()
        end)

        it("should return nil for non-existent version", function()
            fs.writeFile(
                "CHANGELOG.md",
                [[# Changelog

## 1.0.0

### Added

- Something
]]
            )

            local section = extractChangelog("2.0.0")
            expect(section).to.equal(nil)
        end)

        it("should extract last version in changelog", function()
            fs.writeFile(
                "CHANGELOG.md",
                [[# Changelog

## 1.0.0

### Added

- Last version content
]]
            )

            local section = extractChangelog("1.0.0")
            expect(section).to.be.ok()
            expect(string.find(section :: string, "Last version content")).to.be.ok()
        end)
    end)
end
