#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ARCHIVE="$ROOT/archive/research/fprintd/fprintd_1.94.5.orig.tar.bz2"
PATCH="$ROOT/fprintd-patches/0001-fprintd-hide-internal-enroll-preflight.patch"
BUILD_DIR="${FPRINTD_BUILD_DIR:-$ROOT/../fprintd-build-fte4800}"
PREFIX="${PREFIX:-/opt/fte4800/fprintd}"
INSTALL=0

for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    -h|--help)
      echo "Usage: $0 [--install]"
      echo "Builds fprintd 1.94.5 from the preserved source archive and applies the local preflight-status patch."
      echo "With --install, installs only the daemon under $PREFIX and overrides fprintd.service ExecStart."
      exit 0
      ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }
command -v meson >/dev/null || die "meson is required"
command -v ninja >/dev/null || die "ninja is required"
command -v patch >/dev/null || die "patch is required"
command -v tar >/dev/null || die "tar is required"
[ -f "$SOURCE_ARCHIVE" ] || die "missing preserved fprintd source archive: $SOURCE_ARCHIVE"
[ -f "$PATCH" ] || die "missing fprintd patch: $PATCH"

WORK="$(mktemp -d /tmp/fte4800-fprintd.XXXXXX)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

mkdir -p "$WORK/src"
tar -xf "$SOURCE_ARCHIVE" -C "$WORK/src" --strip-components=1
patch -d "$WORK/src" -p1 < "$PATCH"

rm -rf "$BUILD_DIR"
meson setup "$BUILD_DIR" "$WORK/src" \
  --prefix="$PREFIX" --libexecdir=lib/fprintd \
  -Dgtk_doc=false -Dman=false -Dpam=false
ninja -C "$BUILD_DIR" src/fprintd

echo "Built daemon: $BUILD_DIR/src/fprintd"
echo "SHA256: $(sha256sum "$BUILD_DIR/src/fprintd" | awk "{print \$1}")"

if [ "$INSTALL" = 1 ]; then
  DEST="$PREFIX/lib/fprintd/fprintd"
  sudo install -d -m755 "$(dirname "$DEST")"
  if [ -f "$DEST" ]; then
    BACKUP="$DEST.pre-fte4800-$(date +%Y%m%d-%H%M%S)"
    sudo cp -a "$DEST" "$BACKUP"
    echo "Backed up existing custom daemon to $BACKUP"
  fi
  sudo install -m755 "$BUILD_DIR/src/fprintd" "$DEST"

  DROPIN=/etc/systemd/system/fprintd.service.d/20-fte4800-fprintd.conf
  sudo install -d -m755 "$(dirname "$DROPIN")"
  printf "%s\n" "[Service]" "ExecStart=" "ExecStart=$DEST" | sudo tee "$DROPIN" >/dev/null
  sudo systemctl daemon-reload
  sudo systemctl restart fprintd
  echo "Installed custom fprintd daemon: $DEST"
  echo "Systemd override: $DROPIN"
fi
