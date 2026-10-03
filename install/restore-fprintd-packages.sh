#!/usr/bin/env bash
set -euo pipefail

sudo -n true || { echo "ERROR: sudo -n is required for scripted package installation"; exit 1; }

sudo pacman -S --needed \
  --overwrite '/usr/include/libfprint-2/*' \
  --overwrite '/usr/lib/pkgconfig/libfprint-2.pc' \
  --overwrite '/usr/lib/udev/rules.d/70-libfprint-2.rules' \
  --overwrite '/usr/share/metainfo/org.freedesktop.libfprint.metainfo.xml' \
  fprintd libfprint

hash -r

echo
echo "=== restored commands ==="
command -v fprintd-enroll
command -v fprintd-verify
command -v fprintd-list
command -v fprintd-delete

echo
echo "=== package state ==="
pacman -Q fprintd libfprint

echo
echo "=== fprintd service override ==="
systemctl cat fprintd.service | tail -30

echo
echo "=== service ==="
sudo systemctl enable --now fprintd
systemctl is-active fprintd
