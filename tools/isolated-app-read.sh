#!/usr/bin/env bash
set -euo pipefail
sudo -n systemctl stop fprintd.service || true
sudo -n fuser -k /dev/focal_moh_spi || true
sleep 1
sudo -n python3 /home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver/tools/long-windows-read.py
printf '\n=== module ===\n'
src=$(cat /sys/module/focal_spi/srcversion)
echo "srcversion=$src"
printf '%s\n' "$src"
printf '\n=== GPIO ===\n'
sudo -n cat /sys/kernel/debug/gpio | grep -E 'FPNT|FTE4800'
