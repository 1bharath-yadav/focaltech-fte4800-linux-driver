#!/usr/bin/env bash
set -euo pipefail
hash -r
echo "=== commands ==="
command -v fprintd-verify fprintd-enroll fprintd-list fprintd-delete

echo "=== packages ==="
pacman -Q fprintd libfprint libgusb

echo "=== service/library ==="
systemctl is-active fprintd
FPID="$(systemctl show -p MainPID --value fprintd)"
sudo grep 'libfprint-2.so' "/proc/$FPID/maps" | head -5

echo "=== device ==="
fprintd-list "$USER" 2>&1
