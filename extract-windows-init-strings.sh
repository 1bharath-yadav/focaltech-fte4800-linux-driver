#!/usr/bin/env bash
set -euo pipefail
ROOT="/home/archer/projects/zerobook-focaltech-driver"
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$ROOT/windows-focal-strings.txt"

test -f "$DLL"
strings "$DLL" |
  grep -Ei '9368|chip|id|pram|firmware|fw|boot|wake|spi|reset|power' |
  sort -u |
  tee "$OUT"

printf '\n=== COUNT ===\n'
wc -l "$OUT"
printf '\n=== FIRST 160 ===\n'
head -160 "$OUT"
