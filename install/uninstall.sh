#!/usr/bin/env bash
# Remove the focal_spi DKMS module, its udev rule and the module itself.
set -euo pipefail
NAME=focaltech-spi-dkms
VER=1.0.3
if [ "$(id -u)" != 0 ]; then exec sudo "$0" "$@"; fi
systemctl stop fprintd.service 2>/dev/null || true
modprobe -r focal_spi 2>/dev/null || true
dkms remove "$NAME/$VER" --all 2>/dev/null || true
rm -rf "/usr/src/$NAME-$VER"
rm -f /etc/udev/rules.d/70-focal-spi.rules
udevadm control --reload
echo "removed. (If you installed the AUR/distro package '$NAME', remove it with your package manager as well.)"
