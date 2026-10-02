#!/bin/bash
# job2.sh - root run of ffx2.py (Windows-exact wake + framed transaction sweep)
cd "$(dirname "$0")" || exit 1
{ sudo python3 ffx2.py; echo "== dmesg health"; sudo dmesg | grep -Ei 'BUG|Oops|protection|WARNING|KFENCE' | tail -5; echo "(end)"; } 2>&1 | tee job2-out.txt
