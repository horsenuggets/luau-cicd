#!/usr/bin/env bash

# GetReleaseAssetSuffix.sh
#
# Normalizes a release platform's architecture to "x64" or "arm64" for asset names.
# Accepts legacy aliases without changing compiler targets or required CI job names.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    printf '%s\n' 'Expected exactly one release platform argument.' >&2
    printf '%s\n' '[Usage] GetReleaseAssetSuffix.sh <linux|macos|windows>-<x86_64|x64|aarch64|arm64>' >&2
    exit 1
fi

platform=$1
os=${platform%%-*}
arch=${platform#*-}

case "$os" in
    linux|macos|windows) ;;
    *)
        printf 'Unsupported release operating system in "%s". Expected linux, macos, or windows.\n' "$platform" >&2
        exit 1
        ;;
esac

case "$arch" in
    x86_64|x64) arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *)
        printf 'Unsupported release architecture in "%s". Expected x86_64, x64, aarch64, or arm64.\n' "$platform" >&2
        exit 1
        ;;
esac

printf '%s-%s\n' "$os" "$arch"
