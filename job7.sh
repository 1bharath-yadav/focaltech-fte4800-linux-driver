#!/bin/bash
# job7.sh - run diagnose_libfprint.py as root
cd "$(dirname "$0")" || exit 1
{
echo "== kernel module state"
lsmod | grep focal
echo "== device node"
ls -la /dev/focal_moh_spi
echo "== driver binding"
cat /sys/bus/spi/devices/spi-FTE4800:00/driver/module/srcversion 2>/dev/null || echo "not bound"
echo ""
echo "== Running diagnose_libfprint.py"
sudo python3 tools/diagnose_libfprint.py
echo ""
echo "== dmesg focal-trace (last 30)"
dmesg | grep 'focal-trace\|focal ' | tail -30
echo ""
echo "== dmesg health"
dmesg | grep -Ei 'BUG|Oops|protection|WARNING|KFENCE' | tail -5
echo "(end)"
} 2>&1 | tee job7-out.txt
