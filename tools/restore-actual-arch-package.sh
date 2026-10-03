#!/usr/bin/env bash
set -euo pipefail
SRC="/home/archer/projects/zerobook-focaltech-driver/aur-libfprint-ftexx00/pkg/libfprint-ftexx00/usr/lib/libfprint-2.so.2.0.0"
sudo -n cp "$SRC" /usr/lib/libfprint-2.so.2.0.0
sudo -n ln -sf libfprint-2.so.2.0.0 /usr/lib/libfprint-2.so.2
sudo -n systemctl restart fprintd.service || true
sha256sum /usr/lib/libfprint-2.so.2.0.0 "$SRC"
pacman -Qkk libfprint-ftexx00 2>&1 | head -20
