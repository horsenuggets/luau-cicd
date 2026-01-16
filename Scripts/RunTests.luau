#!/usr/bin/env -S lune run

--[[

RunTests

Executes all test suites and exits with appropriate status code.

--]]

local Testable = require("@devpackages/Testable")
local process = require("@lune/process")

-- Disable parallel execution for integration tests that manage file system state
Testable.configure({
    Parallel = false,
})

local TESTS = {
    { Name = "BumpVersionTest", Func = require("../Tests/BumpVersionTest.spec") },
    { Name = "CheckChangelogFormatTest", Func = require("../Tests/CheckChangelogFormatTest.spec") },
    { Name = "CheckChangelogVersionTest", Func = require("../Tests/CheckChangelogVersionTest.spec") },
    { Name = "CheckFileHeadersTest", Func = require("../Tests/CheckFileHeadersTest.spec") },
    { Name = "CheckFormattingTest", Func = require("../Tests/CheckFormattingTest.spec") },
    { Name = "CheckLuaurcFormatTest", Func = require("../Tests/CheckLuaurcFormatTest.spec") },
    { Name = "CheckNoTabsTest", Func = require("../Tests/CheckNoTabsTest.spec") },
    { Name = "CheckRokitFormatTest", Func = require("../Tests/CheckRokitFormatTest.spec") },
    { Name = "CheckVersionMatchTest", Func = require("../Tests/CheckVersionMatchTest.spec") },
    { Name = "CheckWallyFormatTest", Func = require("../Tests/CheckWallyFormatTest.spec") },
    { Name = "EnsureProperVersionUpdateTest", Func = require("../Tests/EnsureProperVersionUpdateTest.spec") },
    { Name = "ExtractChangelogTest", Func = require("../Tests/ExtractChangelogTest.spec") },
    { Name = "ParseVersionTest", Func = require("../Tests/ParseVersionTest.spec") },
    { Name = "SyncVersionTest", Func = require("../Tests/SyncVersionTest.spec") },
}

local function runTests()
    local _, passed = Testable.run(TESTS)
    process.exit(if passed then 0 else 1)
end

runTests()
