#!/bin/bash
set -ex

KVER=$(uname -r)

echo "=== 1. Ensuring pristine backup of libfprint ==="
if [ ! -f /usr/lib/libfprint-2.so.2.0.0.orig ]; then
    cp /usr/lib/libfprint-2.so.2.0.0 /usr/lib/libfprint-2.so.2.0.0.orig
fi

echo "=== 2. Installing hooked libfprint ==="
cp /tmp/libfprint-test-hook.so /usr/lib/libfprint-2.so.2.0.0
chmod 755 /usr/lib/libfprint-2.so.2.0.0

echo "=== 3. Updating DKMS source ==="
cp /home/archer/projects/zerobook-focaltech-driver/focal_spi.c /usr/src/focaltech-spi-dkms-1.0.3/focal_spi.c

echo "=== 4. Rebuilding DKMS module ==="
dkms unbuild focaltech-spi-dkms/1.0.3 -k "$KVER" || true
dkms build focaltech-spi-dkms/1.0.3 -k "$KVER"
dkms install --force focaltech-spi-dkms/1.0.3 -k "$KVER"

echo "=== 5. Stopping fprintd ==="
systemctl stop fprintd || true

echo "=== 6. Unbinding SPI device ==="
if [ -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/devices/spi-FTE4800:00/driver/unbind || true
fi

echo "=== 7. Reloading focal_spi module ==="
rmmod focal_spi || true
modprobe focal_spi trace=1

echo "=== 8. Binding spi-FTE4800:00 to focalfp-spi ==="
echo "" > /sys/bus/spi/devices/spi-FTE4800:00/driver_override || true
if [ ! -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/drivers/focalfp-spi/bind || true
fi

echo "=== 9. Restarting fprintd ==="
systemctl restart fprintd

echo "=== 10. Verification ==="
cat /sys/module/focal_spi/srcversion
ls -la /dev/focal_moh_spi
fprintd-list "$SUDO_USER" || fprintd-list "$USER" || true
echo "=== Complete driver applied and running! ==="
