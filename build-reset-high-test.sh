#!/usr/bin/env bash
set -euo pipefail
ROOT="/home/archer/projects/zerobook-focaltech-driver"
BUILD="$ROOT/reset-high-test"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cp "$ROOT/focal_spi.c" "$BUILD/focal_spi.c"
cp "$ROOT/Makefile" "$BUILD/Makefile"

python3 - "$BUILD/focal_spi.c" <<'PY'
from pathlib import Path
p = Path(__import__("sys").argv[1])
s = p.read_text()
old = '''\tgpiod_set_value_cansleep(data->gpiod_rst, 0);
\tmsleep(50);
\tdev_info(dev, "reset: final logical=0 actual=%d\\n",
\t\t gpiod_get_value_cansleep(data->gpiod_rst));'''
new = '''\tgpiod_set_value_cansleep(data->gpiod_rst, 1);
\tmsleep(100);
\tdev_info(dev, "reset: final logical=1 actual=%d (OUT OF RESET)\\n",
\t\t gpiod_get_value_cansleep(data->gpiod_rst));'''
if old not in s:
    raise SystemExit("reset tail not found")
p.write_text(s.replace(old, new, 1))
PY

make -C "/lib/modules/$(uname -r)/build" M="$BUILD" modules
cp "$BUILD/focal_spi.ko" "$ROOT/focal_spi_reset-high.ko"
printf '%s\n' "BUILT: $(stat -c '%n %s bytes' "$ROOT/focal_spi_reset-high.ko")"
