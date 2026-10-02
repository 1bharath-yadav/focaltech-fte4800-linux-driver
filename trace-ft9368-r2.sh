#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/projects/zerobook-focaltech-driver"
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$ROOT/ft9368-trace.txt"
{
  echo "=== XREFS TO EMBEDDED FT9368 DATA ==="
  r2 -q -c "aaa; axt @ 0x18006d8b0; axt @ 0x180074300" "$DLL" 2>/dev/null || true
  echo
  echo "=== XREFS TO FIRMWARE LOAD STRINGS ==="
  r2 -q -c "aaa; axt @ 0x180037fb0; axt @ 0x180037fe0; axt @ 0x180037f30; axt @ 0x18003a038; axt @ 0x18003a068" "$DLL" 2>/dev/null || true
  echo
  echo "=== FW LOAD FUNCTION DISCOVERY ==="
  r2 -q -c "aaa; afl~loadfirmware; afl~9368; afl~fw9369" "$DLL" 2>/dev/null || true
  echo
  echo "=== SPI FUNCTION DISCOVERY ==="
  r2 -q -c "aaa; afl~spi; afl~ReadChipID; afl~probe_id; afl~init_chip" "$DLL" 2>/dev/null || true
} | tee "$OUT"
echo "Saved: $OUT"
