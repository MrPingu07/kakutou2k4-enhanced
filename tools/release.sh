#!/usr/bin/env bash
#
# tools/release.sh - package and publish a GitHub release.
#
# There is no automated compile step for this mod yet, so prebuilt/ must
# already be refreshed from a build. The script packages it and, with
# --publish, creates/updates the GitHub release via the GitHub CLI.
#
# Usage: tools/release.sh <version> [--publish]
#   Example: tools/release.sh 2.4.0 --publish
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?usage: tools/release.sh <version> [--publish]}"
VERSION="${VERSION#v}"
PUBLISH=0

for arg in "${@:2}"; do
    case "$arg" in
        --publish) PUBLISH=1 ;;
        *) echo "ERROR: unknown option: $arg" >&2; exit 1 ;;
    esac
done

"$ROOT/tools/package.sh" "$VERSION"

ZIP="$ROOT/dist/Kakutou2k4-Enhanced-v$VERSION.zip"
if [ "$PUBLISH" -eq 0 ]; then
    echo "==> dry run. Upload with:"
    echo "    gh release create v$VERSION \"$ZIP\" --title \"Kakutou 2004 Enhanced v$VERSION\" --generate-notes"
    exit 0
fi

if gh release view "v$VERSION" >/dev/null 2>&1; then
    gh release upload "v$VERSION" "$ZIP" --clobber
else
    gh release create "v$VERSION" "$ZIP" \
        --title "Kakutou 2004 Enhanced v$VERSION" \
        --generate-notes
fi
echo "==> published v$VERSION with $ZIP"
