#!/bin/bash
set -e

echo "=== 1. Copying focal_spi.c to DKMS source ==="
sudo cp focal_spi.c /usr/src/focaltech-spi-dkms-1.0.3/focal_spi.c

echo "=== 2. Rebuilding and installing via DKMS with --force ==="
sudo dkms build focaltech-spi-dkms/1.0.3 --force
sudo dkms install focaltech-spi-dkms/1.0.3 --force

echo "=== 3. Stopping fprintd service ==="
sudo systemctl stop fprintd.service

echo "=== 4. Reloading focal_spi module ==="
if lsmod | grep -q focal_spi; then
    sudo rmmod focal_spi
fi
sudo modprobe focal_spi trace=1

echo "=== 5. Starting fprintd service ==="
sudo systemctl start fprintd.service

echo "=== 6. Checking status ==="
modinfo focal_spi | grep srcversion
sudo dmesg | tail -10
systemctl status fprintd.service --no-pager
