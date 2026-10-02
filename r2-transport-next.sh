#!/usr/bin/env bash
set -euo pipefail
ROOT="/home/archer/projects/zerobook-focaltech-driver"
DLL="/run/media/archer/Local Disk/Windows/System32/DriverStore/FileRepository/ftwbioumdfdriverv2.inf_amd64_a4d9dbd54d31f579/ftWbioUmdfDriverV2.dll"
OUT="$ROOT/r2-transport-next.txt"

r2 -2 -q -c '
aaa;
echo === TARGET FUNCTIONS ===;
afl~fw9369_config_spi_mode;
afl~fw9369_probe_id;
afl~SPI0;
afl~ft_interface_spi_RWDevData;
afl~ft_interface_spi_CreateSpiTarget;
afl~ft_interface_spi_WriteGPIO;
echo === CONFIG SPI ===;
s sym.fw9369_config_spi_mode; pdf;
echo === PROBE ID ===;
s sym.fw9369_probe_id; pdf;
echo === SPI SYMBOLS ===;
afl~SPI0;
' "$DLL" | tee "$OUT"

echo "Saved: $OUT"
