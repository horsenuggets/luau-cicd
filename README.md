# luau-cicd

A collection of Luau scripts for CI/CD tasks. Designed to be used as a Git submodule
across Luau projects.

## Usage

Add this repository as a Git submodule...

```bash
git submodule add git@github.com:horsenuggets/luau-cicd.git Submodules/luau-cicd
```

Then run scripts directly...

```bash
./Submodules/luau-cicd/Scripts/CheckFormatting.exec.luau
./Submodules/luau-cicd/Scripts/BumpVersion.exec.luau patch
```

## Workflow Scripts

These scripts replace inline shell in GitHub Actions workflows. The workflow templates in
`Templates/workflows/` already use them. Pass GitHub expressions through `env:` and quote
them as arguments, so they are never interpolated into the shell...

```yaml
- name: Check branch name format
  env:
    BRANCH: ${{ github.head_ref }}
  run: ./Submodules/luau-cicd/Scripts/CheckBranchName.exec.luau "$BRANCH"
```

Every script reports failures as `::error::` annotations on stderr and exits with status
`1`. Here's what each one does...

- `CheckBranchName <branch>` → Requires `<prefix>/<name>` in lowercase kebab-case.
- `CheckReleaseTitle <title>` → Requires exactly `Release X.Y.Z`.
- `CheckReleaseTitleVersion <title>` → Requires the title to match the `VERSION` file.
- `CheckDiffWithMain` → Fetches `main` and requires `HEAD` to have an identical tree.
- `CheckWallyAuth` → Requires `WALLY_AUTH` unless there is no `wally.toml` or the package
  is private.
- `GetReleaseInfo` → Writes `version`, `tag`, and `notes_file` to `GITHUB_OUTPUT`, with
  the notes taken from the matching `CHANGELOG.md` section.
- `CreateGitTag <tag>` → Creates the release tag and pushes it to `origin`.
- `PublishToWally` → Writes `WALLY_AUTH` to `~/.wally/auth.toml` and runs `wally publish`,
  skipping in the same cases as `CheckWallyAuth`.
- `CreateGitHubRelease <tag> <notes> [assets...]` → Publishes the release with `gh`, after
  checking that every asset is nonempty and every ZIP asset is intact.
- `PackageBinary <name> <target>` → Zips `Build/<name>` (or `Build/<name>.exe`) into
  `Build/<name>-<os>-<x64|arm64>.zip` and writes its path to `GITHUB_OUTPUT` as `archive`.
- `GetReleaseAssetSuffix <os>-<arch>` → Prints the canonical asset suffix described below.

## Release Asset Suffixes

Release assets use a canonical `<os>-<arch>` suffix. Supported operating systems are
`linux`, `macos`, and `windows`. Architectures `x86_64` and `x64` normalize to `x64`, and
`aarch64` and `arm64` normalize to `arm64`...

```bash
target=linux-x86_64
suffix=$(./Submodules/luau-cicd/Scripts/GetReleaseAssetSuffix.exec.luau "$target")
# "$suffix" is "linux-x64". "$target" remains "linux-x86_64".
```

The script writes exactly one suffix and a newline to stdout. Invalid arguments produce a
diagnostic on stderr and leave stdout empty. Apply the suffix only when naming release
assets, and keep compiler triples, build matrix targets, and required CI job names
unchanged.
