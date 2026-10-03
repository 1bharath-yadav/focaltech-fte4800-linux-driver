#!/usr/bin/env bash
set -euo pipefail
SRC="/home/archer/projects/zerobook-focaltech-driver/reference/ubuntu_spi/libfprint-2-2_1.94.4+tod1-0ubuntu1~22.04.2_spi_amd64_20240620.deb"
rm -rf /tmp/fprint-ab-src
mkdir -p /tmp/fprint-ab-src /tmp/fprint-ab-src/root
bsdtar -xf "$SRC" -C /tmp/fprint-ab-src
tar --zstd -xf /tmp/fprint-ab-src/data.tar.zst -C /tmp/fprint-ab-src/root
cp /tmp/fprint-ab-src/root/usr/lib/x86_64-linux-gnu/libfprint-2.so.2.0.0 /tmp/libfprint-20240620.so.2.0.0
sha256sum /tmp/libfprint-20240620.so.2.0.0
