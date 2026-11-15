# Changelog

## 0.1.1

- Renamed standalone helpers to PascalCase files with the `.func.luau` suffix.
- Added runtime argument validation and regression tests for shared helpers.
- Aligned script output, tests, documentation, and configuration with current guidelines.
- Removed the obsolete core and shared guideline submodules.
- Fixed version validation, README synchronization, and explicit scan-root exclusions.
- Corrected targeted module headers, native path exclusions, and dependency validation.
- Enforced static-analysis diagnostics from both output streams.
- Managed release protection with current check names and fixed CI workflow setup.

## 0.1.0

- Added the `CheckFileHeaders` script for validating Luau file header comments.
- Added the `CheckLuaurcFormat` script to check `.luaurc` format and Lune alias versions.
- Added the `CheckNoTabs` script for ensuring source files contain no tab characters.
- Added the `CheckRokitFormat` script to check lowercase repo names in `rokit.toml`.
- Added the `CheckWallyFormat` script to check lowercase package names in `wally.toml`.

## 0.0.1

- Added the `CheckChangelogFormat` script for validating changelog formatting.
- Added the `BumpVersion` script for semantic version bumping (patch, minor, and major).
- Added the `SyncVersion` script for syncing `VERSION` to `wally.toml`.
- Added the `CheckFormatting` script for validating StyLua formatting.
- Added the `CheckChangelogVersion` script for validating changelog entries.
- Added the `CheckVersionMatch` script for ensuring `VERSION` matches `wally.toml`.
- Added the `EnsureProperVersionUpdate` script for validating semantic version bumps.
- Added the `ParseVersion` helper for parsing semantic version strings.
- Added the `ExtractChangelog` helper for extracting changelog sections.
- Added a comprehensive test suite with isolated temporary environments.
- Added GitHub Actions workflows for formatting, testing, and release checks.
