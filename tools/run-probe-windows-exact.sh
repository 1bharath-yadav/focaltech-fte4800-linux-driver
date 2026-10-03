#!/bin/bash
# Run the exact Windows-protocol FT9368 probe as root.
# Hypothesis: Replicating the exact Windows SPB sequence (wakeup + 1ms sleep +
# split TX/RX in one CS window) will produce the ROM ID 0x56A2 or chip ID 0x9368.
# Expected: At least one method returns non-zero, non-stale data.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "=== FT9368 Exact Windows Protocol Probe ==="
echo "Driver: $(cat /sys/module/focal_spi/srcversion 2>/dev/null || echo 'not loaded')"
echo "Device: $(ls /dev/focal_moh_spi 2>/dev/null && echo 'present' || echo 'MISSING')"
echo ""
sudo python3 tools/probe-ft9368-windows-exact.py 2>&1 | tee tools/probe-windows-exact-output.log
echo ""
echo "=== dmesg tail ==="
sudo dmesg | tail -30
