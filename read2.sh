#!/bin/bash
f=/home/archer/projects/zerobook-focaltech-driver/enroll_debug.log
# Strip noisy capture-loop spam, keep everything else
grep -av -E "CAPTURE_LOOP_NUM entering state|capture_loop state CAPTURE_LOOP_AWAIT_FINGER_ON|^Updated temperature" $f \
 | sed 's/\(-I-: \[focal\] got finger touched event\.\)\{2,\}/<touch-event xN>/g' | cut -c1-260 > /tmp/enroll_filtered.log
echo "filtered lines: $(wc -l < /tmp/enroll_filtered.log)"
echo "=== all 'enroll: ret' lines (full) ==="
grep -a "enroll: ret" /tmp/enroll_filtered.log | sort | uniq -c
echo "=== first ~70 lines after EnrollStart through first failures ==="
n=$(grep -an "start enrollment device" /tmp/enroll_filtered.log | head -1 | cut -d: -f1)
sed -n "$((n+14)),$((n+110))p" /tmp/enroll_filtered.log
