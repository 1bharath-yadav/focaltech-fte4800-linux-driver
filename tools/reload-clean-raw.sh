#!/usr/bin/env bash
set -euo pipefail
sudo -n systemctl stop fprintd.service || true
sudo -n pkill -x fprintd || true
sleep 1
sudo -n fuser -v /dev/focal_moh_spi || true
sudo -n modprobe -r focal_spi
sudo -n modprobe focal_spi
sleep 1
echo "loaded_srcversion=$(cat /sys/module/focal_spi/srcversion)"
echo "module_file=$(modinfo -F filename focal_spi)"
echo "device=$(readlink -f /sys/bus/spi/devices/spi-FTE4800:00/driver)"
