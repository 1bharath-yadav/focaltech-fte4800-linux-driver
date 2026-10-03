#!/usr/bin/env bash
set -euo pipefail
cd /home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver
exec sudo -n python3 winid.py
