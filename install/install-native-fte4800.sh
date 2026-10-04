#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${LIBFPRINT_BUILD:-$ROOT/../libfprint-upstream/build-fte4800}"
LIB="$BUILD/libfprint/libfprint-2.so.2.0.0"
PREFIX="/opt/fte4800/libfprint"
LIBDIR="$PREFIX/lib"
VENDOR_DIR="/opt/fte4800/vendor"
VENDOR_DLL_SRC="$ROOT/archive/research/windows-package/package/ftWbioEngineAdapter.dll"
VENDOR_DLL="$VENDOR_DIR/ftWbioEngineAdapter.dll"
DROPIN="/etc/systemd/system/fprintd.service.d/00-native-fte4800.conf"
EXPECTED_VENDOR_SHA256="2af887cb0925a29757b9f217f656a9963246ba7770dcc4c68e689ccc6505f06b"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -f "$LIB" ] || die "native libfprint build not found: $LIB"
[ -f "$VENDOR_DLL_SRC" ] || die "FocalTech vendor engine DLL not found: $VENDOR_DLL_SRC"
command -v sudo >/dev/null || die "sudo is required"
sudo -n true || die "sudo -n failed; passwordless sudo is required for this scripted operation"

echo "Installing native FTE4800 libfprint from:"
echo "  $LIB"

sudo install -d -m755 "$LIBDIR"

DEST="$LIBDIR/libfprint-2.so.2.0.0"
if [ -f "$DEST" ]; then
  CURRENT_SHA="$(sha256sum "$DEST" | awk '{print $1}')"
  NEW_SHA="$(sha256sum "$LIB" | awk '{print $1}')"
  if [ "$CURRENT_SHA" != "$NEW_SHA" ]; then
    BACKUP="$DEST.pre-fte4800-$(date +%Y%m%d-%H%M%S)"
    sudo cp -a "$DEST" "$BACKUP"
    echo "Backed up previous native library to:"
    echo "  $BACKUP"
  fi
fi

sudo install -m755 "$LIB" "$DEST"
sudo ln -sfn libfprint-2.so.2.0.0 "$LIBDIR/libfprint-2.so.2"
sudo install -d -m755 "$VENDOR_DIR"
VENDOR_SHA256="$(sha256sum "$VENDOR_DLL_SRC" | awk '{print $1}')"
[ "$VENDOR_SHA256" = "$EXPECTED_VENDOR_SHA256" ] ||
  die "unexpected FocalTech vendor DLL SHA256: $VENDOR_SHA256"
sudo install -m644 "$VENDOR_DLL_SRC" "$VENDOR_DLL"
sudo ln -sfn libfprint-2.so.2 "$LIBDIR/libfprint-2.so"

sudo install -d -m755 /etc/systemd/system/fprintd.service.d
cat <<EOF | sudo tee "$DROPIN" >/dev/null
[Service]
Environment="LD_LIBRARY_PATH=$LIBDIR"
EOF

sudo systemctl daemon-reload
sudo systemctl restart fprintd
sleep 1

FPID="$(systemctl show -p MainPID --value fprintd)"
[ -n "$FPID" ] && [ "$FPID" != "0" ] || die "fprintd did not start"

echo
echo "fprintd main PID: $FPID"
echo "Loaded libfprint mappings:"
sudo grep 'libfprint-2.so' "/proc/$FPID/maps" | head -10 || true

if ! sudo grep -q "$LIBDIR/libfprint-2.so.2.0.0" "/proc/$FPID/maps"; then
  die "fprintd is not loading the project libfprint from $LIBDIR"
fi

echo
echo "Device discovery:"
fprintd-list "$USER" 2>&1 || true

echo
echo "Native driver journal:"
journalctl -u fprintd -n 80 --no-pager -l |
  grep -E 'Initializing FpContext|libfprint version|fte4800|FocalTech FTE4800|find support dev|Device reported probe' |
  tail -40 || true

echo
echo "Vendor engine identity:"
echo "  $VENDOR_DLL"
echo "  SHA256: $(sha256sum "$VENDOR_DLL" | awk '{print $1}')"
echo
echo "Project library identity:"
SYMS="$(mktemp)"
readelf -Ws "$LIB" > "$SYMS"
if ! grep -q 'fte4800_open' "$SYMS"; then
  rm -f "$SYMS"
  die "native fte4800 symbol missing from project library"
fi
rm -f "$SYMS"
echo "Verified: project libfprint contains the native fte4800 driver."

echo
echo "Distro libfprint package remains installed and untouched:"
ls -l /usr/lib/libfprint-2.so.2.0.0

echo
echo "No sudoers changes are performed by the native libfprint installer."
echo
echo "Native libfprint installation complete."
