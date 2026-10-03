#!/usr/bin/env bash
set -u
echo '--- PACKAGES ---'
pacman -Q fprintd libfprint libfprint-ftexx00 2>&1 || true
echo '--- DEVICE ---'
ls -l /dev/focal_moh_spi 2>&1 || true
echo '--- DRIVER ---'
readlink /sys/bus/spi/devices/spi-FTE4800:00/driver 2>&1 || true
cat /sys/bus/spi/devices/spi-FTE4800:00/modalias 2>&1 || true
echo '--- FPRINTD SERVICE ---'
systemctl status fprintd.service --no-pager -l 2>&1 || true
echo '--- JOURNAL FPRINTD ---'
sudo -n journalctl -u fprintd.service -n 160 --no-pager 2>&1 || true
echo '--- FPRINTD LIBRARY FILES ---'
pacman -Ql libfprint-ftexx00 2>&1 | head -100 || true
echo '--- FPRINTD BACKEND STRINGS ---'
strings /usr/lib/libfprint-2.so.2.0.0 2>/dev/null | grep -Ei 'focal|fte|9362|9368|fw9362_dev_init|fw9368|init sensor|configure spi mode' | head -200 || true
echo '--- GDBUS DEVICE ---'
gdbus call --system --dest net.reactivated.Fprint --object-path /net/reactivated/Fprint/Device/0 --method org.freedesktop.DBus.Properties.GetAll net.reactivated.Fprint.Device 2>&1 || true
