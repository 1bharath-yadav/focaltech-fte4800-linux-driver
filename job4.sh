#!/bin/bash
# job4.sh - root run of ffx4.py (active-high reset hypothesis)
cd "$(dirname "$0")" || exit 1
{ sudo python3 ffx4.py; echo "== dmesg health"; sudo dmesg | grep -Ei 'BUG|Oops|protection|WARNING|KFENCE' | tail -5; echo "(end)"; } 2>&1 | tee job4-out.txt
