#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/projects/zerobook-focaltech-driver"
SRC="$ROOT/focal_spi.c"
BUILD="$ROOT/spi-matrix"
KDIR="/lib/modules/$(uname -r)/build"
mkdir -p "$BUILD"
for mode in 0 1 2 3; do
  D="$BUILD/mode${mode}"
  rm -rf "$D"
  mkdir -p "$D"
  sed -e "s/spi->mode = SPI_MODE_0;/spi->mode = SPI_MODE_${mode};/" "$SRC" > "$D/focal_spi.c"
  cp "$ROOT/Makefile" "$D/Makefile"
  make -C "$KDIR" M="$D" modules >/dev/null
  cp "$D/focal_spi.ko" "$BUILD/focal_spi_mode${mode}.ko"
  echo "built mode${mode}: $(stat -c%s "$BUILD/focal_spi_mode${mode}.ko") bytes"
done
echo "Matrix: $BUILD"