#!/usr/bin/env bash
set -euo pipefail
F="/home/archer/projects/zerobook-focaltech-driver/r2-address-analysis.txt"
OUT="/home/archer/projects/zerobook-focaltech-driver/r2-lowlevel-clean.txt"
sed 's/\x1b\[[0-9;]*m//g' "$F" |
  sed -n '99,415p;617,1019p' > "$OUT"
printf '%s\n' '=== LOW LEVEL ANALYSIS ==='
cat "$OUT"
