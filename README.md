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

## Release Asset Suffixes

Use the Bash helper to normalize release asset names across first-party tooling...

```bash
target=linux-x86_64
suffix=$(./Submodules/luau-cicd/Scripts/GetReleaseAssetSuffix.sh "$target")
# "$suffix" is "linux-x64". "$target" remains "linux-x86_64".
```

`GetReleaseAssetSuffix.sh <os>-<arch>` requires exactly one argument. Supported operating
systems are `linux`, `macos`, and `windows`. Architectures `x86_64` and `x64` normalize to
`x64`; `aarch64` and `arm64` normalize to `arm64`. The helper writes exactly one canonical
suffix and a newline to stdout, producing all six combinations of those operating systems
and canonical architectures. Invalid arguments produce a diagnostic on stderr and exit
with status `1`, leaving stdout empty.

Apply the suffix only when naming release assets. Keep compiler triples, build matrix
targets, and required CI job contexts unchanged. Full compiler triples are not accepted as
helper inputs. This helper establishes the naming contract without renaming existing
published assets or changing downstream release workflows.

The repository's existing `run-tests` CI check runs the helper's automated tests through
`./Scripts/RunTests.exec.luau`. Bash must be available to run these tests.
