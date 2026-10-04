#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM="${1:-$ROOT/../libfprint-upstream}"
CANONICAL="$ROOT/libfprint/drivers"
TARGET="$UPSTREAM/libfprint/drivers"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -d "$CANONICAL" ] || die "canonical libfprint source directory missing: $CANONICAL"
[ -d "$TARGET" ] || die "libfprint driver directory missing: $TARGET"

files=(fte4800.c fte4800-match.c fte4800-match.h)

for file in "${files[@]}"; do
  src="$CANONICAL/$file"
  dst="$TARGET/$file"
  [ -f "$src" ] || die "canonical source missing: $src"
  rel="$(realpath --relative-to="$TARGET" "$src")"

  if [ -L "$dst" ]; then
    [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ] || die "unexpected symlink target: $dst -> $(readlink "$dst")"
  elif [ -e "$dst" ]; then
    die "refusing to replace existing upstream file: $dst; move it aside after confirming it is the intended driver source"
  else
    ln -s "$rel" "$dst"
  fi

  [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ] ||
    die "symlink verification failed for $file"
done

echo "libfprint FTE4800 sources linked to canonical project files."
