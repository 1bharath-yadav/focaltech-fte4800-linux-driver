#!/usr/bin/env bash
set -u
printf '%s\n' '=== 1. Kernel/input device ==='
grep -A20 -B5 -i focal /proc/bus/input/devices || true
printf '%s\n' '=== 2. Driver source README ==='
sed -n '1,220p' upstream/README.md
printf '%s\n' '=== 3. Upstream install scripts ==='
sed -n '1,220p' upstream/installspi.sh
printf '%s\n' '--- libfprint installer ---'
sed -n '1,220p' upstream/installlib.sh
printf '%s\n' '=== 4. Current fprint packages ==='
pacman -Qi libfprint fprintd 2>/dev/null | grep -E '^(Name|Version|Install Date|Description)' || true
printf '%s\n' '=== 5. FTE device nodes ==='
stat /dev/focal_moh_spi 2>/dev/null || true
printf '%s\n' '=== 6. Driver logs ==='
sudo journalctl -k -b --no-pager | grep -Ei 'focal|fte4800|focalfp|finger' | tail -100 || true
