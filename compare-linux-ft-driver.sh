#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/projects/zerobook-focaltech-driver"
{
  echo "=== LOCAL DRIVER FIRMWARE/FT9368 REFERENCES ==="
  grep -RniE "9368|9369|firmware|AA55|PRAM|boot|sram|transfer" "$ROOT" --include="*.c" --include="*.h" | head -500 || true
  echo
  echo "=== UPSTREAM SOURCE FILES ==="
  find "$ROOT/upstream" -type f -print | grep -E "\.(c|h)$" | sort | head -160
  echo
  echo "=== FTE3600 SOURCE FILES ==="
  find "$ROOT/libfprint-fte3600" -type f -print | grep -E "\.(c|h)$" | sort | head -160
} | tee "$ROOT/compare-linux.txt"
echo "Saved: $ROOT/compare-linux.txt"
