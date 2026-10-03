#!/usr/bin/env bash
set -u
echo '--- interrupts ---'
grep -Ei 'focal|spi|143:' /proc/interrupts || true
echo '--- gpio lines ---'
sudo -n cat /sys/kernel/debug/gpio 2>/dev/null | grep -Ei 'gpio-3|gpio-4|FPNT|focal|reset' || true
echo '--- recent kernel ---'
sudo -n dmesg | tail -80 | grep -Ei 'focal|gpio-3|spi-FTE4800' || true
