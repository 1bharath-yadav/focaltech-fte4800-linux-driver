#!/usr/bin/env bash
set -euo pipefail
ROOT="/home/archer/projects/zerobook-focaltech-driver"
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$ROOT/r2-address-analysis.txt"

r2 -2 -q -c '
aaa;
echo === 18000FC84 ===;
s 0x18000fc84; pd 80;
echo === 180018024 ===;
s 0x180018024; pd 80;
echo === 180018080 ===;
s 0x180018080; pd 80;
echo === 18000F62C ===;
s 0x18000f62c; pd 100;
echo === 18001B450 ===;
s 0x18001b450; pd 80;
echo === 18001B4E4 ===;
s 0x18001b4e4; pd 100;
echo === 18001B684 ===;
s 0x18001b684; pd 120;
echo === 18001B74C ===;
s 0x18001b74c; pd 120;
echo === 18001B808 ===;
s 0x18001b808; pd 120;
echo === 18001BCF8 ===;
s 0x18001bcf8; pd 160;
echo === 18001C2A8 ===;
s 0x18001c2a8; pd 120;
' "$DLL" > "$OUT"

cat "$OUT"
