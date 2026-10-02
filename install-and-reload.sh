#!/bin/bash
set -ex

KVER=$(uname -r)

echo "=== 1. Copying to DKMS source ==="
cp focal_spi.c /usr/src/focaltech-spi-dkms-1.0.3/focal_spi.c

echo "=== 2. Cleaning DKMS cache and rebuilding ==="
dkms unbuild focaltech-spi-dkms/1.0.3 -k "$KVER" || true
dkms build focaltech-spi-dkms/1.0.3 -k "$KVER"
dkms install --force focaltech-spi-dkms/1.0.3 -k "$KVER"

echo "=== 3. Stopping fprintd ==="
systemctl stop fprintd || true

echo "=== 4. Unbinding SPI device ==="
if [ -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/devices/spi-FTE4800:00/driver/unbind || true
fi

echo "=== 5. Reloading focal_spi module ==="
rmmod focal_spi || true
modprobe focal_spi trace=1

echo "=== 6. Binding spi-FTE4800:00 to focalfp-spi ==="
echo "" > /sys/bus/spi/devices/spi-FTE4800:00/driver_override || true
if [ ! -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/drivers/focalfp-spi/bind || true
fi

echo "=== 7. Starting fprintd ==="
systemctl restart fprintd

echo "=== 8. Verification ==="
modinfo focal_spi | grep -E '^srcversion|^version'
cat /sys/module/focal_spi/srcversion
ls -la /dev/focal_moh_spi
fprintd-list "$SUDO_USER" || fprintd-list "$USER" || true
echo "=== Module reloaded and verified successfully! ==="
