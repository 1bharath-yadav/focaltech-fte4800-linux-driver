#!/usr/bin/env bash
# Needs root. Loads patched focal_spi, verifies power/reset state. No ioctl, no firmware writes.
set -u
D=/home/archer/projects/zerobook-focaltech-driver
OUT=$D/install-safe.out
exec > >(tee "$OUT") 2>&1
echo "== $(date) =="
rmmod fte4800_pwr 2>&1 || true          # camera-PMIC GPIO hack, unrelated to FPNT
rmmod focal_spi 2>&1 || true
insmod $D/focal_spi.ko && echo "insmod OK"
sleep 1
SPIDEV=spi-FTE4800:00
echo "driver bound: $(basename "$(readlink /sys/bus/spi/devices/$SPIDEV/driver 2>/dev/null)")"
if [ "$(basename "$(readlink /sys/bus/spi/devices/$SPIDEV/driver 2>/dev/null)")" != "focalfp-spi" ]; then
  echo "$SPIDEV" > /sys/bus/spi/drivers/spidev/unbind 2>/dev/null || true
  echo "$SPIDEV" > /sys/bus/spi/drivers/focalfp-spi/bind 2>&1 || true
  sleep 1
  echo "driver bound now: $(basename "$(readlink /sys/bus/spi/devices/$SPIDEV/driver 2>/dev/null)")"
fi
echo "--- dmesg (focal/FTE/spi) ---"; dmesg | grep -i "focal\|fte4800\|reset:" | tail -25
echo "--- gpio users ---"; grep -i "fte\|focal\|spi" /sys/kernel/debug/gpio 2>&1 | head
echo "--- misc node ---"; ls -la /dev/focal_moh_spi
chown archer:archer "$OUT"
