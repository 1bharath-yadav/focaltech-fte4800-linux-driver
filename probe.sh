#!/usr/bin/env bash
set -u
printf '%s\n' '=== DMI ==='
for f in sys_vendor product_name product_version bios_version; do printf '%-16s ' "$f:"; cat "/sys/class/dmi/id/$f" 2>/dev/null || true; done
printf '%s\n' '=== ACPI candidates ==='
find /sys/bus/acpi/devices -maxdepth 1 -type l 2>/dev/null | grep -Ei 'FTE|FPNT|FPC|ELAN|GOOD|SYNA|EGIS' || true
printf '%s\n' '=== FTE/FPNT details ==='
for d in /sys/bus/acpi/devices/*FTE* /sys/bus/acpi/devices/*FPNT*; do [ -e "$d" ] || continue; echo "--- $d"; readlink -f "$d"; for f in status modalias hid; do [ -f "$d/$f" ] && cat "$d/$f"; done; done
printf '%s\n' '=== SPI devices ==='
for d in /sys/bus/spi/devices/*; do [ -e "$d" ] || continue; echo "--- $d"; readlink -f "$d"; cat "$d/modalias" 2>/dev/null || true; done
printf '%s\n' '=== I2C named devices ==='
for d in /sys/bus/i2c/devices/*; do [ -e "$d" ] || continue; n=$(cat "$d/name" 2>/dev/null || :); m=$(cat "$d/modalias" 2>/dev/null || :); case "$n $m" in *FTE*|*Focal*|*finger*|*Finger*|*FPC*|*Goodix*|*ELAN*|*SYNA*) echo "--- $d name=$n modalias=$m";; esac; done
printf '%s\n' '=== modules ==='
lsmod | grep -Ei 'focal|fprint|spi|hid' || true
printf '%s\n' '=== fprint discovery ==='
fprintd-list 2>&1 || true
