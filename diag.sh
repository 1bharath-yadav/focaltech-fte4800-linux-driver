#!/bin/bash
# Read-only diagnostics for the enroll-swipe-too-short investigation
echo "=== loaded module srcversion vs on-disk ==="
cat /sys/module/focal_spi/srcversion 2>&1
sudo -n modinfo focal_spi 2>&1 | grep -E "^(filename|srcversion|version)"
echo
echo "=== dmesg: jitter lines (last 30) ==="
sudo -n dmesg | grep -E "generated full frame|Finger touch" | tail -30
echo
echo "=== dmesg: errors/warnings from focal (last 20) ==="
sudo -n dmesg | grep -i focal | grep -iE "err|fail|warn|overheat|timeout|invalid" | tail -20
echo
echo "=== fprintd journal (last 25, truncated lines) ==="
sudo -n journalctl -u fprintd --no-pager -n 25 | cut -c1-200
echo
echo "=== fprintd binary / lib in use ==="
pid=$(pgrep -x fprintd | head -1)
echo "pid=$pid"
[ -n "$pid" ] && sudo -n grep -E "libfprint" /proc/$pid/maps | awk '{print $6}' | sort -u
ls -la /usr/lib/libfprint-2.so.2.0.0*
