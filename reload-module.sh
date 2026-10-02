#!/bin/bash
set -e

echo "=== Stopping fprintd ==="
systemctl stop fprintd || true

echo "=== Unbinding old device ==="
if [ -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/devices/spi-FTE4800:00/driver/unbind || true
fi

echo "=== Removing old focal_spi ==="
rmmod focal_spi || true

echo "=== Inserting new focal_spi.ko ==="
insmod /home/archer/projects/zerobook-focaltech-driver/focal_spi.ko trace=1

echo "=== Binding to spi-FTE4800:00 ==="
echo "" > /sys/bus/spi/devices/spi-FTE4800:00/driver_override || true
echo "spi-FTE4800:00" > /sys/bus/spi/drivers/focalfp-spi/bind || true

echo "=== Restarting fprintd ==="
systemctl restart fprintd

echo "=== Verification ==="
cat /sys/module/focal_spi/srcversion
ls -la /dev/focal_moh_spi
fprintd-list "$SUDO_USER" || fprintd-list "$USER" || true
echo "=== Done ==="
