#!/usr/bin/env bash
set -u
echo '=== ENROLL ==='
timeout 12s fprintd-enroll "$USER" 2>&1
rc=$?
echo "enroll_exit=$rc"
echo '=== DAEMON ==='
sudo -n journalctl -u fprintd.service --since '30 seconds ago' --no-pager 2>&1 | grep -Ei 'focal|fw936|device id|spi mode|init sensor|claim|open|enroll|error' || true
echo '=== KERNEL ==='
sudo -n dmesg | tail -280 | grep -E 'focal-fte4800|REQ (read|write)|TX:|RX:' | tail -220 || true
