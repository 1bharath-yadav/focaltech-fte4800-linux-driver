#!/bin/bash
set -ex
# Stop
systemctl stop fprintd 2>/dev/null || true
pkill -f fprintd 2>/dev/null || true
sleep 1

# Reload module
rmmod focal_spi 2>/dev/null || true
sleep 1
insmod /home/archer/projects/zerobook-focaltech-driver/focal_spi.ko trace=1
sleep 2

# Bind
echo "" > /sys/bus/spi/devices/spi-FTE4800:00/driver_override 2>/dev/null || true
[ ! -e /sys/bus/spi/devices/spi-FTE4800:00/driver ] && echo "spi-FTE4800:00" > /sys/bus/spi/drivers/focalfp-spi/bind 2>/dev/null || true

# Clean
rm -rf /var/lib/fprint/archer/ 2>/dev/null || true
dmesg -C

# Restart
systemctl restart fprintd
sleep 3

echo "srcver: $(cat /sys/module/focal_spi/srcversion)"
echo "READY"
