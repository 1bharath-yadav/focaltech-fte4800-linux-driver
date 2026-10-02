#!/bin/bash
cd "$(dirname "$0")" || exit 1
{ sudo python3 ffx5.py; sudo dmesg | grep -Ei "BUG|Oops|protection|WARNING|KFENCE" | tail -5; echo "(end)"; } 2>&1 | tee job5-out.txt
