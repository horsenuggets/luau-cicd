--[[

RunTests

Executes all test suites and exits with appropriate status code.

--]]

local Testable = require("@devpackages/testable")
local process = require("@lune/process")

-- Disable parallel execution to avoid file conflicts in tests
Testable.configure({
    Parallel = false,
})

local TESTS = {
    { Name = "ExtractChangelogTest", Func = require("../Tests/ExtractChangelogTest.spec") },
    { Name = "ParseVersionTest", Func = require("../Tests/ParseVersionTest.spec") },
}

local function runTests()
    local _, passed = Testable.run(TESTS)
    process.exit(if passed then 0 else 1)
end

runTests()
