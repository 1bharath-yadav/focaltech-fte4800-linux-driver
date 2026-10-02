#!/usr/bin/env bash
set -euo pipefail
ROOT="/home/archer/projects/zerobook-focaltech-driver"
SRC="$ROOT/focal_spi.c"

python3 - "$SRC" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = """static void focal_spi_reset(struct focal_fp_data *data)
{
\tgpiod_set_value(data->gpiod_rst, 0);
\tmsleep(10);
\tgpiod_set_value(data->gpiod_rst, 1);
}
"""
new = """static void focal_spi_reset(struct focal_fp_data *data)
{
\t/* gpiod values are logical; ACPI marks the FTE4800 reset GPIO active-low. */
\tgpiod_set_value_cansleep(data->gpiod_rst, 0); /* inactive/deasserted */
\tusleep_range(5000, 6000);
\tgpiod_set_value_cansleep(data->gpiod_rst, 1); /* assert reset */
\tusleep_range(5000, 6000);
\tgpiod_set_value_cansleep(data->gpiod_rst, 0); /* deassert reset */
\tmsleep(50);
}
"""
if old not in s:
    raise SystemExit("expected reset function not found; refusing to patch")
p.write_text(s.replace(old, new, 1))
PY

"$ROOT/build-spi-matrix.sh"

echo "Patched reset sequence and rebuilt SPI mode matrix."
