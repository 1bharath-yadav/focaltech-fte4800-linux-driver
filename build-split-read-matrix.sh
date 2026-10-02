#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/archer/projects/zerobook-focaltech-driver"
SRC="$ROOT/focal_spi.c"
BUILD="$ROOT/spi-split-matrix"
KDIR="/lib/modules/$(uname -r)/build"

mkdir -p "$BUILD"

python3 - "$SRC" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = """\tif(tx_len>0){
\t\ttx_buf=fp_data->wr_buf;\t
\t\tret=spi_write_then_read(spi,tx_buf, tx_len, fp_data->rd_buf, rx_len);
\t\treturn ret;
\t}

\treturn spi_read(spi, fp_data->rd_buf, rx_len);
"""
new = """\tif(tx_len>0){
\t\ttx_buf=fp_data->wr_buf;
\t\t/* Match the OEM Windows FT9368 transport: write and read are
\t\t * separate SPI transactions, rather than one write_then_read. */
\t\tret=spi_write(spi, tx_buf, tx_len);
\t\tif (ret < 0)
\t\t\treturn ret;
\t}

\treturn spi_read(spi, fp_data->rd_buf, rx_len);
"""
if old not in s:
    raise SystemExit("expected focal_spi_read block not found; refusing to patch")
Path("/tmp/focal_spi_split.c").write_text(s.replace(old, new, 1))
PY

for mode in 0 1 2 3; do
  D="$BUILD/mode${mode}"
  rm -rf "$D"
  mkdir -p "$D"
  sed "s/spi->mode = SPI_MODE_0;/spi->mode = SPI_MODE_${mode};/"     /tmp/focal_spi_split.c > "$D/focal_spi.c"
  cp "$ROOT/Makefile" "$D/Makefile"
  make -C "$KDIR" M="$D" modules >/dev/null
  cp "$D/focal_spi.ko" "$BUILD/focal_spi_mode${mode}.ko"
  echo "built split mode${mode}: $(stat -c%s "$BUILD/focal_spi_mode${mode}.ko") bytes"
done

echo "Split-transaction matrix built: $BUILD"
