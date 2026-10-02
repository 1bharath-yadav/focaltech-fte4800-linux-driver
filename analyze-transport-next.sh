#!/usr/bin/env bash
set -euo pipefail
ROOT="/home/archer/projects/zerobook-focaltech-driver"
OUT="$ROOT/next-transport-analysis.txt"
ASM="$ROOT/ft9368-functions.asm"

{
  echo "=== FOCAL LOW-LEVEL FUNCTION LOCATIONS ==="
  rg -n 'fcn\.180018024|fcn\.180018080|fcn\.18000f62c|fcn\.18001b450|fcn\.18001b4e4|fcn\.18001b684|fcn\.18001b74c|fcn\.18001b808|fcn\.18001bcf8|SPI0_CMD_Set|SPI0_Read_SPI|SPI0_Wakeup' "$ASM" || true

  echo
  echo "=== SOURCE DRIVER SPI CALL SITES ==="
  rg -n -C 12 'spi_write\(|spi_read\(|spi_write_then_read\(' "$ROOT/focal_spi.c"

  echo
  echo "=== CURRENT SPI DEVICE ATTRIBUTES ==="
  for f in     /sys/bus/spi/devices/spi-FTE4800:00/modalias     /sys/bus/spi/devices/spi-FTE4800:00/uevent     /sys/bus/spi/devices/spi-FTE4800:00/spi_master/spi1/uevent; do
    echo "--- $f"
    cat "$f" 2>/dev/null || true
  done

  echo
  echo "=== CONTROLLER/DEVICE DIRECTORY ==="
  ls -la /sys/bus/spi/devices/spi-FTE4800:00
} | tee "$OUT"

echo
echo "Saved: $OUT"
