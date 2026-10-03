#!/usr/bin/env bash
set -u
echo '--- daemon recent ---'
sudo -n journalctl -u fprintd.service --since '25 seconds ago' --no-pager 2>&1 | grep -Ei 'focal|fw936|capture|finger|image|error|enroll' | tail -100 || true
echo '--- irq ---'
grep -E ' 143:|focal-irq' /proc/interrupts || true
