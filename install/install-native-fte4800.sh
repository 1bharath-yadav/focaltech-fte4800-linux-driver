#!/usr/bin/env bash
set -euo pipefail

BUILD="${LIBFPRINT_BUILD:-/home/archer/projects/zerobook-focaltech-driver/libfprint-upstream/build-fte}"
LIB="$BUILD/libfprint/libfprint-2.so.2.0.0"
PREFIX="/opt/fte4800/libfprint"
LIBDIR="$PREFIX/lib"
DROPIN="/etc/systemd/system/fprintd.service.d/00-native-fte4800.conf"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -f "$LIB" ] || die "native libfprint build not found: $LIB"
command -v sudo >/dev/null || die "sudo is required"
sudo -n true || die "sudo -n failed; passwordless sudo is required for this scripted operation"

echo "Installing native FTE4800 libfprint from:"
echo "  $LIB"

sudo install -d -m755 "$LIBDIR"
sudo install -m755 "$LIB" "$LIBDIR/libfprint-2.so.2.0.0"
sudo ln -sfn libfprint-2.so.2.0.0 "$LIBDIR/libfprint-2.so.2"
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

if [ -f /etc/sudoers.d/archer-nopasswd ]; then
  sudo rm -f /etc/sudoers.d/archer-nopasswd
  echo "Removed temporary /etc/sudoers.d/archer-nopasswd"
fi

echo
echo "Native libfprint installation complete."
