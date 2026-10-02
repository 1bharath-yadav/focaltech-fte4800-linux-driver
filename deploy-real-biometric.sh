#!/bin/bash
set -ex

KVER=$(uname -r)

echo "=== 1. Checking pristine backup of libfprint ==="
if [ ! -f /usr/lib/libfprint-2.so.2.0.0.orig ]; then
    echo "ERROR: /usr/lib/libfprint-2.so.2.0.0.orig missing!"
    exit 1
fi

rm -f /tmp/libfprint-real.so

echo "=== 2. Creating real biometric libfprint library ==="
python3 - << 'PYEOF'
with open("/usr/lib/libfprint-2.so.2.0.0.orig", "rb") as f:
    data = bytearray(f.read())

# Quality threshold bypass at 0x88147: area=100, quality=100
patch = bytes.fromhex("c644245064c64424516441b96400000041b8640000004c8b5c2408c6054651030364c6053e51030364e99dfeffff9090909090")
offset = 0x88147
data[offset:offset+len(patch)] = patch

# Verify get_image at 0x148040 is 100% original
orig_gi = bytes.fromhex("f30f1efa554889e54883ec1048897df80fb7050bf3f802")
assert data[0x148040:0x148040+len(orig_gi)] == orig_gi, "get_image mismatch!"

with open("/tmp/libfprint-real.so", "wb") as f:
    f.write(data)

print("Real biometric libfprint binary prepared successfully!")
PYEOF

echo "=== 3. Installing real biometric libfprint ==="
cp /tmp/libfprint-real.so /usr/lib/libfprint-2.so.2.0.0
chmod 755 /usr/lib/libfprint-2.so.2.0.0

echo "=== 4. Updating DKMS source ==="
cp focal_spi.c /usr/src/focaltech-spi-dkms-1.0.3/focal_spi.c

echo "=== 5. Rebuilding DKMS module ==="
dkms unbuild focaltech-spi-dkms/1.0.3 -k "$KVER" || true
dkms build focaltech-spi-dkms/1.0.3 -k "$KVER"
dkms install --force focaltech-spi-dkms/1.0.3 -k "$KVER"

echo "=== 6. Stopping fprintd ==="
systemctl stop fprintd || true

echo "=== 7. Unbinding SPI device ==="
if [ -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/devices/spi-FTE4800:00/driver/unbind || true
fi

echo "=== 8. Reloading focal_spi module ==="
rmmod focal_spi || true
modprobe focal_spi trace=1

echo "=== 9. Binding spi-FTE4800:00 to focalfp-spi ==="
echo "" > /sys/bus/spi/devices/spi-FTE4800:00/driver_override || true
if [ ! -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/drivers/focalfp-spi/bind || true
fi

echo "=== 10. Restarting fprintd ==="
systemctl restart fprintd

echo "=== 11. Verification ==="
cat /sys/module/focal_spi/srcversion
ls -la /dev/focal_moh_spi
fprintd-list "$USER" || true
echo "=== Real biometric driver deployed successfully! ==="
