#!/usr/bin/env bash
set -euo pipefail
cd /home/archer/projects/zerobook-focaltech-driver
sed -i 's/spi->chip_select);/spi_get_chipselect(spi, 0));/' focal_spi.c
make -j$(nproc)
echo "diagnostic build complete"
