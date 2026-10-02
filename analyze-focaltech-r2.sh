#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/projects/zerobook-focaltech-driver"
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$ROOT/r2-analysis.txt"
{
  echo "=== DLL INFO ==="
  rabin2 -I "$DLL"
  echo
  echo "=== DLL STRINGS: FT9368/FW ==="
  rabin2 -zz "$DLL" | grep -Ei "FT9368|FT9369|fw9369|LoadFW|bin code|pramboot|focaltech|FTE4800" | head -300 || true
  echo
  echo "=== RADARE2 XREFS ==="
  r2 -q -c "aaa; iz~FT9368; iz~fw9369; iz~LoadFW; iz~9348; iz~pramboot; afl~9368; afl~9369" "$DLL" 2>/dev/null || true
  echo
  echo "=== LINUX LIB INFO ==="
  rabin2 -I /usr/lib/libfprint-2.so.2.0.0 2>/dev/null | head -80 || true
  echo
  echo "=== CURRENT DEVICE LOG ==="
  journalctl -k -b --no-pager 2>/dev/null | grep -Ei "focal|FTE4800|spi1|fprint" | tail -120 || true
} | tee "$OUT"
echo "Saved: $OUT"
