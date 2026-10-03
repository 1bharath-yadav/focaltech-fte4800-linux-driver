#!/usr/bin/env bash
set -euo pipefail
sudo -n systemctl stop fprintd.service || true
sudo -n fuser -k /dev/focal_moh_spi || true
exec sudo -n /usr/bin/python3 /home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver/tools/exact-ft9368-boot-probe.py
