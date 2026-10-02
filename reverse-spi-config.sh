#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/projects/zerobook-focaltech-driver"
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$ROOT/spi-config-reverse.txt"
{
  echo "=== FUNCTION SEARCH ==="
  r2 -q -e scr.color=false -c 'aaa; afl~fw9369_config_spi_mode; afl~CreateSpiTarget; afl~RWDevData; afl~WriteGPIO; afl~SendControlTransferSynchronously; afl~PrepareHardware; afl~ReadChipID; afl~probe_id' "$DLL" 2>/dev/null || true
  echo
  echo "=== SPI MODE CONFIG ==="
  r2 -q -e scr.color=false -c 'aaa; s sym.fw9369_config_spi_mode; pdf' "$DLL" 2>/dev/null || true
  echo
  echo "=== CREATE SPI TARGET ==="
  r2 -q -e scr.color=false -c 'aaa; s sym.clsSpiDev::ft_interface_spi_CreateSpiTarget; pdf' "$DLL" 2>/dev/null || true
  echo
  echo "=== RW DEVICE DATA ==="
  r2 -q -e scr.color=false -c 'aaa; s sym.clsSpiDev::ft_interface_spi_RWDevData; pdf' "$DLL" 2>/dev/null || true
  echo
  echo "=== WRITE GPIO ==="
  r2 -q -e scr.color=false -c 'aaa; s sym.clsSpiDev::ft_interface_spi_WriteGPIO; pdf' "$DLL" 2>/dev/null || true
  echo
  echo "=== PREPARE HARDWARE ==="
  r2 -q -e scr.color=false -c 'aaa; s sym.clsSpiDev::ft_interface_base_PrepareHardware; pdf' "$DLL" 2>/dev/null || true
  echo
  echo "=== SPI-RELATED IMPORTS/SYMBOLS ==="
  rabin2 -s "$DLL" 2>/dev/null | grep -Ei 'spi|gpio|wdf|deviceio|ioctl' | head -250 || true
} | tee "$OUT"
echo "Saved: $OUT"
