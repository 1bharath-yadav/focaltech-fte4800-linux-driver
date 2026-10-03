#!/usr/bin/env bash
set -u
ROOT=/home/archer/projects/zerobook-focaltech-driver
CLEAN=$ROOT/.worktrees/fte4800-clean-driver
sudo -n systemctl stop fprintd.service || true
sudo -n fuser -k /dev/focal_moh_spi || true
sudo -n modprobe -r focal_spi || true
sudo -n insmod "$ROOT/focal_spi.ko" trace=1
sleep 1
cd "$ROOT"
sudo -n python3 winid.py > "$CLEAN/ab-legacy-winid.out" 2>&1 || true
grep -E "CHIP ID|hits:|<== CHIP ID|mode=0 hz=4000k reset=1 settle=0.4" "$CLEAN/ab-legacy-winid.out" | tail -30 || true
sudo -n fuser -k /dev/focal_moh_spi || true
sudo -n modprobe -r focal_spi || true
sudo -n modprobe focal_spi
sleep 1
echo "restored_srcversion=$(cat /sys/module/focal_spi/srcversion)"
echo "restored_driver=$(basename "$(readlink /sys/bus/spi/devices/spi-FTE4800:00/driver)")"
sudo -n systemctl restart fprintd.service || true
