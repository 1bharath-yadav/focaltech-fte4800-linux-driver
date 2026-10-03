#!/usr/bin/env bash
# Install the FTE4800 / FT9368 SPI transport driver (focal_spi) through DKMS.
#
#   sudo ./install/install.sh            install, load, run the identity self-test
#   sudo ./install/install.sh --check    only check prerequisites, change nothing
#   sudo ./install/install.sh --no-test  skip the hardware self-test
#   sudo ./install/install.sh --force    install even if no FTE4800 ACPI device is found
#
# This installs the kernel transport driver ONLY. It does not install or change
# libfprint / fprintd and does not touch PAM, so it cannot enable fingerprint login.
set -euo pipefail

NAME=focaltech-spi-dkms
VER=1.0.3
SRC=/usr/src/$NAME-$VER
HERE=$(cd "$(dirname "$0")/.." && pwd)
CHECK=0 TEST=1 FORCE=0
for a in "$@"; do
  case $a in
    --check) CHECK=1 ;;
    --no-test) TEST=0 ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

say() { printf '\n== %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

say "prerequisites"
ACPI=$(ls /sys/bus/acpi/devices 2>/dev/null | grep -m1 '^FTE4800' || true)
if [ -n "$ACPI" ]; then echo "ACPI device: $ACPI"
elif [ "$FORCE" = 1 ]; then echo "WARNING: no FTE4800 ACPI device found (continuing: --force)"
else die "no FTE4800 ACPI device found; this driver is for laptops with ACPI id FTE4800 (see README 'Other laptops')"; fi
command -v dkms >/dev/null || die "dkms is not installed (Arch: pacman -S dkms; Debian/Ubuntu: apt install dkms; Fedora: dnf install dkms)"
[ -d "/lib/modules/$(uname -r)/build" ] || die "kernel headers for $(uname -r) are missing (Arch: pacman -S linux-headers or the headers matching your kernel package)"
if grep -q -E 'generate_synthetic_frame|stage_shifts|fp_sqrt|generate_fingerprint_frame' "$HERE/focal_spi.c"; then
  die "focal_spi.c contains synthetic-frame code; refusing to install"
fi
echo "dkms: $(dkms --version 2>/dev/null | head -1)   kernel: $(uname -r)"
[ "$CHECK" = 1 ] && { echo "prerequisites OK"; exit 0; }

if [ "$(id -u)" != 0 ]; then exec sudo "$0" "$@"; fi

say "install sources to $SRC"
dkms remove "$NAME/$VER" --all >/dev/null 2>&1 || true
rm -rf "$SRC"
install -d "$SRC/protocol"
install -m 0644 "$HERE/focal_spi.c" "$HERE/Makefile" "$HERE/dkms.conf" "$SRC/"
install -m 0644 "$HERE/protocol/"*.h "$SRC/protocol/"

say "dkms add/build/install"
dkms add "$NAME/$VER"
dkms build "$NAME/$VER"
dkms install --force "$NAME/$VER"

say "udev rule (/dev/focal_moh_spi -> group wheel + uaccess)"
install -m 0644 "$HERE/install/70-focal-spi.rules" /etc/udev/rules.d/70-focal-spi.rules
udevadm control --reload

say "load module"
systemctl stop fprintd.service 2>/dev/null || true
modprobe -r focal_spi 2>/dev/null || true
modprobe focal_spi
sleep 1
DEV=$(ls /sys/bus/spi/devices 2>/dev/null | grep -m1 FTE4800 || true)
if [ -n "$DEV" ]; then
  DRV=$(basename "$(readlink "/sys/bus/spi/devices/$DEV/driver" 2>/dev/null || true)")
  if [ "$DRV" != "focal-fte4800" ]; then
    echo "$DEV bound to '${DRV:-nothing}', rebinding to focal-fte4800"
    echo "$DEV" > "/sys/bus/spi/drivers/${DRV:-spidev}/unbind" 2>/dev/null || true
    echo "" > "/sys/bus/spi/devices/$DEV/driver_override" 2>/dev/null || true
    echo "$DEV" > /sys/bus/spi/drivers/focal-fte4800/bind
    sleep 1
  fi
fi
udevadm trigger --subsystem-match=misc --action=change 2>/dev/null || true
sleep 1
[ -e /dev/focal_moh_spi ] || die "/dev/focal_moh_spi did not appear; check 'dmesg | grep -i focal'"
ls -l /dev/focal_moh_spi

if [ "$TEST" = 1 ]; then
  say "hardware identity self-test"
  python3 "$HERE/tools/fte4800_selftest.py" --reset || die "self-test failed; see README 'Troubleshooting'"
fi
say "done: kernel transport driver installed. Fingerprint login is NOT enabled (see README)."
