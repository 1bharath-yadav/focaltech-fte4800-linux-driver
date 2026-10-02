#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
MATRIX="$ROOT/spi-split-matrix"
T="$ROOT/spi-direct-test/test_register.py"

echo "Stopping fprintd..."
systemctl stop fprintd.service 2>/dev/null || true
systemctl mask --runtime fprintd.service >/dev/null 2>&1 || true
pkill -x fprintd 2>/dev/null || true
sleep 1

for mode in 0 1 2 3; do
  echo "===== SPLIT SPI MODE ${mode} @ 1 MHz ====="
  rmmod focal_spi 2>/dev/null || true
  insmod "$MATRIX/focal_spi_mode${mode}.ko"
  sleep 0.15
  if python3 "$T"; then
    echo "RESULT split-mode${mode}: PASS"
  else
    rc=$?
    echo "RESULT split-mode${mode}: FAIL(rc=${rc})"
  fi
done

echo "===== Restore SPLIT MODE 0 ====="
rmmod focal_spi 2>/dev/null || true
insmod "$MATRIX/focal_spi_mode0.ko"
systemctl unmask fprintd.service >/dev/null 2>&1 || true
systemctl restart fprintd.service 2>/dev/null || true
echo "Done."
