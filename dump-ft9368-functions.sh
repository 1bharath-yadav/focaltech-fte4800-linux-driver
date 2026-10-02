#!/usr/bin/env bash
set -euo pipefail
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$HOME/projects/zerobook-focaltech-driver/ft9368-functions.asm"
{
  for f in     0x18002179c     0x180021a04     0x180021b68     0x18002a934     0x180018814; do
    echo "===== $f ====="
    r2 -q -c "aaa; pdf @ $f" "$DLL" 2>/dev/null
    echo
  done
} | tee "$OUT"
echo "Saved: $OUT"
