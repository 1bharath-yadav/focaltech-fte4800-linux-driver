#!/usr/bin/env bash
set -u
DEV=spi-FTE4800:00
printf 'driver=%s\n' "$(basename "$(readlink "/sys/bus/spi/devices/$DEV/driver" 2>/dev/null || true)")"
printf 'override=%s\n' "$(cat "/sys/bus/spi/devices/$DEV/driver_override" 2>/dev/null || true)"
printf 'module=%s\n' "$(cat /sys/module/focal_spi/srcversion 2>/dev/null || echo absent)"
ls -l /dev/spidev1.0 /dev/focal_moh_spi 2>/dev/null || true
printf 'focal-driver-dir:\n'
ls /sys/bus/spi/drivers/focal-fte4800 2>/dev/null || true
printf 'spidev-driver-dir:\n'
ls /sys/bus/spi/drivers/spidev 2>/dev/null || true
