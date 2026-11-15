--[[

HasAnalysisIssues.func

Reports failed analysis processes or diagnostics on either output stream. Informational
analyzer logs do not count as diagnostics.

--]]

const ISSUE_PATTERN = "%):%s+%w+:"

const function HasAnalysisIssues(ok: boolean, stdout: string, stderr: string): boolean
    assert(type(ok) == "boolean", "Expected a boolean process status.")
    assert(type(stdout) == "string", "Expected a string for standard output.")
    assert(type(stderr) == "string", "Expected a string for standard error.")

    return not ok or string.find(stdout, ISSUE_PATTERN) ~= nil or string.find(stderr, ISSUE_PATTERN) ~= nil
end

return HasAnalysisIssues
