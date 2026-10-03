#!/usr/bin/env bash
set -euo pipefail
sudo -n kill -TERM 114992 114977 2>/dev/null || true
sleep 1
sudo -n fuser -v /dev/focal_moh_spi || true
sudo -n modprobe -r focal_spi
sudo -n modprobe focal_spi
sleep 1
echo "loaded_srcversion=$(cat /sys/module/focal_spi/srcversion)"
echo "module_file=$(modinfo -F filename focal_spi)"
echo "driver=$(basename "$(readlink /sys/bus/spi/devices/spi-FTE4800:00/driver)")"
