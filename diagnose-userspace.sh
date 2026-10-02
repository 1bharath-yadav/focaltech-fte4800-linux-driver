#!/usr/bin/env bash
set -u
printf '%s\n' '=== Packages ==='
pacman -Q libfprint libfprint-ftexx00 fprintd 2>/dev/null || true
printf '%s\n' '=== libfprint files ==='
pacman -Ql libfprint-ftexx00 2>/dev/null | grep -E 'libfprint|udev|systemd' || true
printf '%s\n' '=== shared library ==='
ldconfig -p 2>/dev/null | grep libfprint || true
printf '%s\n' '=== fprintd service ==='
systemctl status fprintd --no-pager 2>&1 || true
printf '%s\n' '=== fprintd journal ==='
journalctl -u fprintd -b --no-pager -n 120 2>&1 || true
printf '%s\n' '=== udev rules ==='
grep -RniE 'focal|fprint|focal_moh_spi' /usr/lib/udev/rules.d /etc/udev/rules.d 2>/dev/null || true
printf '%s\n' '=== device ==='
ls -l /dev/focal_moh_spi 2>/dev/null || true
printf '%s\n' '=== driver ==='
readlink /sys/bus/spi/devices/spi-FTE4800:00/driver 2>/dev/null || echo unbound
