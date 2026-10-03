#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DKMS_SRC="/usr/src/focaltech-spi-dkms-1.0.3"
KVER="$(uname -r)"

sudo -n true

echo "== clean FTE4800 DKMS install =="
echo "root: $ROOT"
echo "kernel: $KVER"

echo "== sync source to DKMS =="
sudo cp "$ROOT/focal_spi.c" "$DKMS_SRC/focal_spi.c"
sudo rm -rf "$DKMS_SRC/protocol"
sudo cp -a "$ROOT/protocol" "$DKMS_SRC/protocol"

echo "== rebuild DKMS from clean source =="
sudo dkms unbuild "focaltech-spi-dkms/1.0.3" -k "$KVER" || true
sudo dkms build "focaltech-spi-dkms/1.0.3" -k "$KVER"
sudo dkms install --force "focaltech-spi-dkms/1.0.3" -k "$KVER"

echo "== stop userspace biometric service =="
sudo systemctl stop fprintd.service || true

echo "== unload current driver =="
sudo modprobe -r focal_spi || true

echo "== load clean driver =="
sudo modprobe focal_spi
sleep 1

echo "== binding =="
DEV="spi-FTE4800:00"
DRIVER="$(basename "$(readlink "/sys/bus/spi/devices/$DEV/driver" 2>/dev/null || true)")"
if [ "$DRIVER" != "focal-fte4800" ]; then
    echo "$DEV" | sudo tee "/sys/bus/spi/drivers/spidev/unbind" >/dev/null 2>&1 || true
    echo "" | sudo tee "/sys/bus/spi/devices/$DEV/driver_override" >/dev/null 2>&1 || true
    echo "$DEV" | sudo tee "/sys/bus/spi/drivers/focal-fte4800/bind" >/dev/null
    sleep 1
    DRIVER="$(basename "$(readlink "/sys/bus/spi/devices/$DEV/driver" 2>/dev/null || true)")"
fi

echo "driver=$DRIVER"
echo "module_srcversion=$(cat /sys/module/focal_spi/srcversion)"
echo "source_sha256=$(sha256sum "$ROOT/focal_spi.c" | cut -d' ' -f1)"
echo "dkms_sha256=$(sudo sha256sum "$DKMS_SRC/focal_spi.c" | cut -d' ' -f1)"
echo "device_node=$(ls -l /dev/focal_moh_spi)"

echo "== kernel health =="
sudo dmesg | grep -Ei "focal|FTE4800|spi1" | tail -40 || true

echo "== restart fprintd =="
sudo systemctl restart fprintd.service
echo "== DONE =="