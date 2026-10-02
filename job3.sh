#!/bin/bash
# job3.sh - root run of ffx3.py (turnaround-gap sweep)
cd "$(dirname "$0")" || exit 1
{ sudo python3 ffx3.py; echo "== dmesg health"; sudo dmesg | grep -Ei 'BUG|Oops|protection|WARNING|KFENCE' | tail -5; echo "(end)"; } 2>&1 | tee job3-out.txt
