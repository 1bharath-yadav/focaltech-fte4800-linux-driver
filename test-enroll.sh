#!/bin/bash
set -e

echo "Starting enrollment..."
timeout 120 fprintd-enroll -f right-index-finger archer 2>&1 &
EPID=$!
sleep 6

for i in $(seq 1 14); do
    echo "--- Touch $i ---"
    echo 1 > /sys/module/focal_spi/parameters/touch_trigger
    sleep 3
    if ! kill -0 $EPID 2>/dev/null; then
        echo "Exited after touch $i"
        break
    fi
done

wait $EPID 2>/dev/null || true
echo "=== Exit ==="

journalctl -u fprintd --since "3 min ago" --no-pager | grep -i "enroll\|quality\|error\|fail\|result\|complete\|stage\|swipe\|core\|dump" | tail -30
echo "---"
fprintd-list archer 2>&1 || true
