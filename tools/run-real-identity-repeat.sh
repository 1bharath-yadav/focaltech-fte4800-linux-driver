#!/usr/bin/env bash
set -euo pipefail
for i in 1 2 3 4 5; do
    echo "=== identity run $i ==="
    sudo -n python3 '/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver/tools/fte4800_selftest.py' --reset
done
