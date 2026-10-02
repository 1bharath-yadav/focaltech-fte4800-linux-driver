#!/bin/bash
since="${1:-14:50:04}"
out=/home/archer/projects/zerobook-focaltech-driver/enroll_debug.log
sudo -n journalctl -u fprintd --no-pager --since "$(date +%Y-%m-%d) $since" -o cat > $out
echo "total bytes: $(wc -c < $out)  lines: $(wc -l < $out)"
echo "=== de-spammed (collapse repeated touch events) ==="
sed 's/\(-I-: \[focal\] got finger touched event\.\)\{2,\}/<touch-event x N>/g' $out | cut -c1-300 | head -150
echo "=== key lines ==="
grep -aoE "(swipe too short[^\\n]{0,60}|not enough frames[^\\n]{0,40}|enroll: ret = [^\\n]{0,80}|force enroll: [^\\n]{0,60}|should move a little[^\\n]{0,60}|already existence[^\\n]{0,60}|fail to enroll[^\\n]{0,60}|enroll success[^\\n]{0,40}|Enrollment (has )?failed[^\\n]{0,40}|enrollRet = [^\\n]{0,20}|forceEnrollRet = [^\\n]{0,20})" $out | head -60
