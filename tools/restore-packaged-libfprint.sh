#!/usr/bin/env bash
set -euo pipefail
DEB="/home/archer/projects/zerobook-focaltech-driver/reference/ubuntu_spi/libfprint-2-2_1.94.4+tod1-0ubuntu1~22.04.2_spi_20250112_amd64.deb"
rm -rf /tmp/fprint-20250112
mkdir -p /tmp/fprint-20250112/root
bsdtar -xf "$DEB" -C /tmp/fprint-20250112
tar --zstd -xf /tmp/fprint-20250112/data.tar.zst -C /tmp/fprint-20250112/root
sha256sum /tmp/fprint-20250112/root/usr/lib/x86_64-linux-gnu/libfprint-2.so.2.0.0
sudo -n cp /tmp/fprint-20250112/root/usr/lib/x86_64-linux-gnu/libfprint-2.so.2.0.0 /usr/lib/libfprint-2.so.2.0.0
sudo -n ln -sf libfprint-2.so.2.0.0 /usr/lib/libfprint-2.so.2
sudo -n systemctl daemon-reload
sudo -n systemctl restart fprintd.service || true
pacman -Qkk libfprint-ftexx00 2>&1 | head -30
