#!/usr/bin/env bash
set -euo pipefail
REPO=https://github.com/vobademi/FTEXX00-Ubuntu.git
if [ ! -d upstream ]; then git clone --depth=1 "$REPO" upstream; else git -C upstream pull --ff-only; fi
printf "\\n=== Upstream FTE driver ===\\n"
grep -nE "FTE4800|focal_spi|acpi_match" upstream/focal_spi.c | head -30
printf "\\n=== Kernel build environment ===\\n"
printf "kernel=%s\\n" "$(uname -r)"
test -d "/usr/lib/modules/$(uname -r)/build" && echo headers=present || echo headers=missing
printf "\\n=== ACPI/SPI target ===\\n"
readlink -f /sys/bus/spi/devices/spi-FTE4800:00
readlink /sys/bus/spi/devices/spi-FTE4800:00/driver 2>/dev/null || echo unbound
