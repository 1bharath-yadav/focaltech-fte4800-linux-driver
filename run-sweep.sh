#!/bin/bash
# run-sweep.sh -- run as root:  sudo bash run-sweep.sh
# Loads the xfer-capable focal_spi, checks bind + reset, runs the transport sweep.
cd "$(dirname "$0")" || exit 1
set -u
echo "== swap module (new build: spi_sync debug ioctl)"
rmmod focal_spi 2>&1
insmod ./focal_spi.ko trace=0 || { echo INSMOD_FAILED; exit 1; }
sleep 1
echo "driver: $(readlink /sys/bus/spi/devices/spi-FTE4800:00/driver)  override=[$(cat /sys/bus/spi/devices/spi-FTE4800:00/driver_override)]"
ls -l /dev/focal_moh_spi
echo "== probe log"; dmesg | grep -Ei 'focal|FTE4800' | tail -8
echo "== gpio state"; grep -Ei 'FTE4800|FPNT' /sys/kernel/debug/gpio 2>&1 | head
echo "== sweep"
python3 ffx.py --reset 2>&1 | tee sweep-summary.txt
echo "== kernel health after sweep"; dmesg | grep -Ei 'BUG|Oops|general protection|WARNING|KFENCE' | tail -5; echo "(end)"
