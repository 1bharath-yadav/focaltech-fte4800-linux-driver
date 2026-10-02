#!/usr/bin/env bash
set -euo pipefail
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$HOME/projects/zerobook-focaltech-driver/ft9368-clean.asm"
r2 -q -e scr.color=false -c "aaa; pdf @ 0x18002179c; pdf @ 0x180021a04; pdf @ 0x18001aa98; pdf @ 0x180019340" "$DLL" 2>/dev/null | tee "$OUT"
echo "Saved: $OUT"
