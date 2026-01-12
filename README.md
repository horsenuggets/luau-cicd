# luau-cicd

A collection of Luau scripts for CI/CD tasks. Designed to be used as a git submodule across Luau projects.

## Usage

Add this repository as a git submodule:

```bash
git submodule add git@github.com:horsenuggets/luau-cicd.git Submodules/luau-cicd
```

Then run scripts using Lune:

```bash
lune run Submodules/luau-cicd/Scripts/CheckFormatting
lune run Submodules/luau-cicd/Scripts/BumpVersion patch
```
