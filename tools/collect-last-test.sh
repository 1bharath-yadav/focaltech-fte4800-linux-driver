#!/usr/bin/env bash
set -u
sudo -n dmesg | grep -Ei 'focal|FTE4800' | tail -120
printf '\n=== IRQ ===\n'
grep -Ei 'focal-irq|spi-FTE4800' /proc/interrupts || true
