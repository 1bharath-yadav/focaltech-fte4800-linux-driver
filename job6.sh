#!/bin/bash
# job6.sh - run as root:  bash job6.sh
cd "$(dirname "$0")" || exit 1
{ python3 winid.py; cat job6-out.txt 2>/dev/null | tail -3; dmesg | grep -Ei "BUG|Oops|protection|WARNING|KFENCE" | tail -5; echo "(end)"; } 2>&1 | tee job6-out.txt
