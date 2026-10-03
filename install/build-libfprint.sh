#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROJECT_ROOT=$(cd "$ROOT/../.." && pwd)
PATCH="$ROOT/libfprint-patches/0001-native-fte4800-ft9368-driver.patch"
SRC="${1:-$PROJECT_ROOT/libfprint-upstream}"
BUILD="${BUILD_DIR:-$SRC/build-fte4800}"
PREFIX="${PREFIX:-/usr}"
INSTALL=0

for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    -h|--help)
      sed -n '1,24p' "$0"
      exit 0
      ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

command -v git >/dev/null || die "git is required"
command -v meson >/dev/null || die "meson is required"
command -v ninja >/dev/null || die "ninja is required"
command -v gcc >/dev/null || die "gcc is required"
command -v pkg-config >/dev/null || die "pkg-config is required"

git -C "$SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  die "libfprint source tree not found: $SRC"
[ -f "$PATCH" ] || die "driver patch not found: $PATCH"

BASE=396119347a6947efc6a43edc4708d5581dd13686
HEAD=$(git -C "$SRC" rev-parse HEAD)
[ "$HEAD" = "$BASE" ] || die "expected libfprint commit $BASE, got $HEAD"

if ! git -C "$SRC" diff --quiet || ! git -C "$SRC" diff --cached --quiet; then
  die "libfprint source tree is dirty; use a clean checkout before applying the driver patch"
fi

if git -C "$SRC" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
  echo "patch already applied"
else
  git -C "$SRC" apply --check "$PATCH"
  git -C "$SRC" apply "$PATCH"
fi

meson setup "$BUILD" "$SRC" --prefix="$PREFIX" -Ddoc=false -Ddrivers=fte4800
ninja -C "$BUILD" -j2

echo
echo "Built: $BUILD/libfprint/libfprint-2.so.2.0.0"
echo "No system library was changed."

if [ "$INSTALL" = 1 ]; then
  if [ "$(id -u)" -eq 0 ]; then
    ninja -C "$BUILD" install
  else
    sudo ninja -C "$BUILD" install
  fi
  echo "Installed libfprint to $PREFIX."
fi
