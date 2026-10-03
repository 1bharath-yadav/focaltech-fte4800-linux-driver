#!/usr/bin/env bash
set -u
echo '--- recent kernel requests ---'
sudo -n dmesg | tail -260 | grep -E 'focal-fte4800 (REQ|TX:|RX:)' | tail -220 || true
echo '--- recent fprintd ---'
sudo -n journalctl -u fprintd.service --since '45 seconds ago' --no-pager 2>&1 | grep -Ei 'ioctl|poll|capture_loop|finger|focal|enroll' | tail -140 || true
