#!/usr/bin/env bash
# Copy the stress-test skill from michaelhil/stress-test-skill into this
# plugin. Run before tagging a claude-toolbox release to pick up upstream
# changes. Not run automatically — bundling is an explicit snapshot.
#
# Usage:
#   scripts/sync-stress-test.sh           # use pinned ref from PIN file
#   scripts/sync-stress-test.sh main      # sync from upstream main
#   scripts/sync-stress-test.sh v0.3      # sync from a specific tag/SHA
#
# After running, review the diff, update PIN, bump plugin version, commit.

set -euo pipefail

cd "$(dirname "$0")/.."

REPO="https://github.com/michaelhil/stress-test-skill.git"
PIN_FILE="skills/stress-test/.upstream-pin"
REF="${1:-$(cat "$PIN_FILE" 2>/dev/null || echo main)}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Cloning $REPO at $REF..."
git clone --quiet --depth 1 --branch "$REF" "$REPO" "$TMP/src" 2>/dev/null || {
  # Branch flag fails on SHAs — fall back to full clone + checkout
  git clone --quiet "$REPO" "$TMP/src"
  git -C "$TMP/src" checkout --quiet "$REF"
}

SHA=$(git -C "$TMP/src" rev-parse --short HEAD)

mkdir -p skills/stress-test/references
cp "$TMP/src/skill/SKILL.md" skills/stress-test/SKILL.md
cp -R "$TMP/src/skill/references/." skills/stress-test/references/ 2>/dev/null || true

printf '%s\n' "$SHA" > "$PIN_FILE"

echo "Synced stress-test skill at $SHA (ref: $REF)"
echo "Pin recorded in $PIN_FILE"
echo
echo "Next: review 'git diff', bump plugin version in .claude-plugin/plugin.json, commit."
