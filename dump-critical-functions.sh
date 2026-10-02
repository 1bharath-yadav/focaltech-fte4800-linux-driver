#!/usr/bin/env bash
set -euo pipefail
ROOT="/home/archer/projects/zerobook-focaltech-driver"
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$ROOT/r2-critical-functions.txt"

r2 -2 -q -e scr.color=false -c '
aaa;
echo === fcn.18000f4c4 ===; s 0x18000f4c4; pdf;
echo === fcn.18000f62c ===; s 0x18000f62c; pdf;
echo === fcn.18000fc84 ===; s 0x18000fc84; pdf;
echo === fcn.18001b450 ===; s 0x18001b450; pdf;
echo === fcn.18001b4e4 ===; s 0x18001b4e4; pdf;
echo === fcn.18001b684 ===; s 0x18001b684; pdf;
echo === fcn.18001bcf8 ===; s 0x18001bcf8; pdf;
echo === fcn.18001c2a8 ===; s 0x18001c2a8; pdf;
' "$DLL" > "$OUT"

wc -l "$OUT"
