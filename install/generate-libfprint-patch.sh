#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM="${1:-$ROOT/../libfprint-upstream}"
PATCH="$ROOT/libfprint-patches/0001-native-fte4800-ft9368-driver.patch"
BASE=396119347a6947efc6a43edc4708d5581dd13686
TMP="$(mktemp -d /tmp/fte4800-patch-tree.XXXXXX)"
cleanup() {
  git -C "$UPSTREAM" worktree remove "$TMP" --force >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

git -C "$UPSTREAM" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERROR: libfprint source tree not found: $UPSTREAM" >&2; exit 1;
}

git -C "$UPSTREAM" worktree add --detach "$TMP" HEAD >/dev/null
for file in fte4800.c fte4800-match.c fte4800-match.h; do
  cp "$ROOT/libfprint/drivers/$file" "$TMP/libfprint/drivers/$file"
done

git -C "$TMP" diff --check "$BASE" --
git -C "$TMP" diff --binary "$BASE" -- > "$PATCH"

# The patch file itself contains diff context lines with leading spaces.
# Validate source files above; do not run whitespace checks against the patch text.
echo "Generated: $PATCH"
echo "Base: $BASE"
