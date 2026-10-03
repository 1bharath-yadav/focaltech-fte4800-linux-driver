#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${FTE4800_HOME_DIR:-$HOME}"
PROJECT="${FTE4800_PROJECT_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
ARCHIVE="$PROJECT/archive"

mkdir -p "$ARCHIVE"

if ! grep -qxF '/archive/' "$PROJECT/.gitignore"; then
  {
    echo
    echo "# Local research/archive data (intentionally untracked)"
    echo '/archive/'
  } >> "$PROJECT/.gitignore"
fi

shopt -s nullglob
dat_files=("$HOME_DIR"/*.dat)
if ((${#dat_files[@]})); then
  mv -- "${dat_files[@]}" "$ARCHIVE"/
fi

for item in \
  "$HOME_DIR/fte4800-local" \
  "$HOME_DIR/fte4800-archive-20261003.tar.zst"
do
  if [ -e "$item" ]; then
    mv -- "$item" "$ARCHIVE"/
  fi
done

echo "=== archive ==="
du -sh "$ARCHIVE"
find "$ARCHIVE" -maxdepth 2 -mindepth 1 -printf '%P %y %s bytes\n' | sort | head -160

echo
echo "=== home root remaining fingerprint-named items ==="
find "$HOME_DIR" -maxdepth 1 -mindepth 1 \( -iname '*fprint*' -o -iname '*finger*' -o -iname '*focal*' -o -iname '*fte*' -o -iname '*ft9368*' \) -printf '%f\n' | sort

echo
echo "=== home root remaining .dat ==="
find "$HOME_DIR" -maxdepth 1 -type f -name '*.dat' -printf '%f\n' | sort

echo
echo "=== git status ==="
git -C "$PROJECT" status --short

echo
echo "=== archive ignored ==="
git -C "$PROJECT" check-ignore -v archive 2>/dev/null || true
