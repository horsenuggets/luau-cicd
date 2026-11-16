#!/usr/bin/env -S lune run

--[[

RunTests.exec

Executes all test suites and exits with appropriate status code.

--]]

const Testable = require("@devpackages/Testable")
const process = require("@lune/process")

const TESTS = {
    { Func = require("../Tests/BumpVersionTest.spec"), Name = "BumpVersionTest" },
    { Func = require("../Tests/CheckBranchNameTest.spec"), Name = "CheckBranchNameTest" },
    { Func = require("../Tests/CheckChangelogFormatTest.spec"), Name = "CheckChangelogFormatTest" },
    { Func = require("../Tests/CheckChangelogVersionTest.spec"), Name = "CheckChangelogVersionTest" },
    { Func = require("../Tests/CheckDiffWithMainTest.spec"), Name = "CheckDiffWithMainTest" },
    { Func = require("../Tests/CheckFileHeadersTest.spec"), Name = "CheckFileHeadersTest" },
    { Func = require("../Tests/CheckFormattingTest.spec"), Name = "CheckFormattingTest" },
    { Func = require("../Tests/CheckLuaurcFormatTest.spec"), Name = "CheckLuaurcFormatTest" },
    { Func = require("../Tests/CheckNoTabsTest.spec"), Name = "CheckNoTabsTest" },
    { Func = require("../Tests/CheckReleaseTitleTest.spec"), Name = "CheckReleaseTitleTest" },
    { Func = require("../Tests/CheckReleaseTitleVersionTest.spec"), Name = "CheckReleaseTitleVersionTest" },
    { Func = require("../Tests/CheckRokitFormatTest.spec"), Name = "CheckRokitFormatTest" },
    { Func = require("../Tests/CheckVersionMatchTest.spec"), Name = "CheckVersionMatchTest" },
    { Func = require("../Tests/CheckWallyAuthTest.spec"), Name = "CheckWallyAuthTest" },
    { Func = require("../Tests/CheckWallyFormatTest.spec"), Name = "CheckWallyFormatTest" },
    { Func = require("../Tests/CompareReleaseVersionsTest.spec"), Name = "CompareReleaseVersionsTest" },
    { Func = require("../Tests/CreateGitHubReleaseTest.spec"), Name = "CreateGitHubReleaseTest" },
    { Func = require("../Tests/CreateGitTagTest.spec"), Name = "CreateGitTagTest" },
    { Func = require("../Tests/EnsureProperVersionUpdateTest.spec"), Name = "EnsureProperVersionUpdateTest" },
    { Func = require("../Tests/ExtractChangelogTest.spec"), Name = "ExtractChangelogTest" },
    { Func = require("../Tests/GetReleaseAssetSuffixTest.spec"), Name = "GetReleaseAssetSuffixTest" },
    { Func = require("../Tests/GetReleaseInfoTest.spec"), Name = "GetReleaseInfoTest" },
    { Func = require("../Tests/IsExcludedPathTest.spec"), Name = "IsExcludedPathTest" },
    { Func = require("../Tests/IsReleaseVersionTest.spec"), Name = "IsReleaseVersionTest" },
    { Func = require("../Tests/LintTest.spec"), Name = "LintTest" },
    { Func = require("../Tests/PackageBinaryTest.spec"), Name = "PackageBinaryTest" },
    { Func = require("../Tests/ParseVersionTest.spec"), Name = "ParseVersionTest" },
    { Func = require("../Tests/PublishToWallyTest.spec"), Name = "PublishToWallyTest" },
    { Func = require("../Tests/SyncVersionTest.spec"), Name = "SyncVersionTest" },
    { Func = require("../Tests/TestEnvironmentTest.spec"), Name = "TestEnvironmentTest" },
    { Func = require("../Tests/WriteGitHubOutputsTest.spec"), Name = "WriteGitHubOutputsTest" },
}

const RunTests = {}

function RunTests.exec()
    -- Disable parallel execution for integration tests that manage file system state.
    Testable.configure({
        Parallel = false,
    })

    const _, passed = Testable.run(TESTS)
    process.exit(if passed then 0 else 1)
end

RunTests.exec()
