#!/usr/bin/env bash
set -euo pipefail

cd /home/archer/projects/zerobook-focaltech-driver

cp -a focal_spi.c focal_spi.c.bak-acpi-spi

python3 - <<'PY'
from pathlib import Path

p = Path("focal_spi.c")
s = p.read_text()

old = """\t/* Set up SPI*/
\tspi->max_speed_hz=4*1000*1000;
\tspi->bits_per_word = 8;
\t/*if spi transfer err,change here spi->mode = SPI_MODE_0*/
\tspi->mode = SPI_MODE_0|SPI_CS_HIGH;"""

new = """\t/* Match the FTE4800 ACPI resource on ZERO BOOK 13:
\t * active-low chip select, SPI mode 0, 1 MHz clock. */
\tspi->max_speed_hz = 1 * 1000 * 1000;
\tspi->bits_per_word = 8;
\tspi->mode = SPI_MODE_0;"""

if old not in s:
    raise SystemExit("Expected SPI setup block was not found")

p.write_text(s.replace(old, new, 1))
PY

make clean
make

sudo systemctl stop fprintd || true
sudo modprobe -r focal_spi || true
sudo insmod ./focal_spi.ko

sleep 1

echo
echo "=== DRIVER ==="
readlink -f /sys/bus/spi/devices/spi-FTE4800:00/driver

echo
echo "=== DEVICE ==="
fprintd-list "$USER"

echo
echo "=== ENROLL TEST ==="
set +e
timeout 10s fprintd-enroll
rc=$?
set -e

echo
echo "=== KERNEL LOG ==="
journalctl -k -b --no-pager --since "30 seconds ago" |
    grep -Ei 'focal|fte4800|spi|irq|error|fail' |
    tail -100

echo
echo "=== RESULT CODE ==="
echo "$rc"

exit "$rc"
