#!/usr/bin/env bash
# Prints the next semantic version for a bump level, based on the latest X.Y.Z git tag.
#
# Usage: next-version.sh <major|minor|patch>
# Tags use the bare `X.Y.Z` form (no `v` prefix), matching the release workflow trigger.
set -euo pipefail

level="${1:?usage: next-version.sh <major|minor|patch>}"

latest="$(git tag --list '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1)"
if [ -z "$latest" ]; then
    latest="0.0.0"
fi

IFS=. read -r major minor patch <<<"$latest"

case "$level" in
    major)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
    minor)
        minor=$((minor + 1))
        patch=0
        ;;
    patch)
        patch=$((patch + 1))
        ;;
    *)
        echo "error: unknown bump level '$level' (expected major|minor|patch)" >&2
        exit 1
        ;;
esac

echo "${major}.${minor}.${patch}"
