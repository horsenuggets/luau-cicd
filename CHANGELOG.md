# Changelog

## 0.0.1
- Added CheckChangelogFormat script for validating changelog follows exact format from guidelines
- Added BumpVersion script for semantic version bumping (patch, minor, major)
- Added SyncVersion script for syncing VERSION file to wally.toml
- Added CheckFormatting script for validating stylua formatting
- Added CheckChangelogVersion script for validating changelog entries
- Added CheckVersionMatch script for ensuring VERSION matches wally.toml
- Added EnsureProperVersionUpdate script for validating semantic version bumps
- Added parseVersion helper for parsing semantic version strings
- Added extractChangelog helper for extracting changelog sections
- Added comprehensive test suite with isolated temp environments
- Added GitHub Actions workflows for formatting, testing, and release checks
