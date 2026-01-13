# Changelog

## 0.0.1

### Added

- BumpVersion script for semantic version bumping (patch, minor, major)
- SyncVersion script for syncing VERSION file to wally.toml
- CheckFormatting script for validating stylua formatting
- CheckChangelogVersion script for validating changelog entries
- CheckVersionMatch script for ensuring VERSION matches wally.toml
- EnsureProperVersionUpdate script for validating semantic version bumps
- parseVersion helper for parsing semantic version strings
- extractChangelog helper for extracting changelog sections
- Comprehensive test suite with 48 tests using isolated temp environments
- GitHub Actions workflows for formatting, testing, and release checks
