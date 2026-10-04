#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$ROOT/../libfprint-upstream}"
BUILD="${BUILD_DIR:-$SRC/build-fte4800}"
PREFIX="${PREFIX:-/opt/fte4800/libfprint}"
INSTALL=0

for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    -h|--help)
      cat <<EOF
Usage: $0 [LIBFPRINT_TREE] [--install]

The canonical FTE4800 sources live in:
  $ROOT/libfprint/drivers/

The selected libfprint checkout is linked to those files before building.
The distribution libfprint package is not modified unless --install is used.
EOF
      exit 0
      ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

command -v meson >/dev/null || die "meson is required"
command -v ninja >/dev/null || die "ninja is required"
command -v gcc >/dev/null || die "gcc is required"
command -v pkg-config >/dev/null || die "pkg-config is required"

git -C "$SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  die "libfprint source tree not found: $SRC"

"$ROOT/install/link-libfprint-source.sh" "$SRC"

for file in fte4800.c fte4800-match.c fte4800-match.h; do
  link="$SRC/libfprint/drivers/$file"
  [ -L "$link" ] || die "expected source symlink is missing: $link"
done

if [ -f "$BUILD/build.ninja" ]; then
  meson setup "$BUILD" "$SRC" --reconfigure \
    --prefix="$PREFIX" -Ddoc=false -Ddrivers=fte4800
else
  meson setup "$BUILD" "$SRC" \
    --prefix="$PREFIX" -Ddoc=false -Ddrivers=fte4800
fi

ninja -C "$BUILD" -j2

echo
echo "Built: $BUILD/libfprint/libfprint-2.so.2.0.0"
echo "Canonical source: $ROOT/libfprint/drivers/"
echo "No system library was changed."

if [ "$INSTALL" = 1 ]; then
  if [ "$(id -u)" -eq 0 ]; then
    ninja -C "$BUILD" install
  else
    sudo ninja -C "$BUILD" install
  fi
  echo "Installed libfprint to $PREFIX."
fi
