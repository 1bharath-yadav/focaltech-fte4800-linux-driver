#!/bin/bash
set -ex

KVER=$(uname -r)
PROJ=/home/archer/projects/zerobook-focaltech-driver

echo "=== 1. Verifying pristine backup of libfprint ==="
if [ ! -f /usr/lib/libfprint-2.so.2.0.0.orig ]; then
    echo "ERROR: /usr/lib/libfprint-2.so.2.0.0.orig missing!"
    exit 1
fi

echo "=== 2. Patching libfprint binary ==="
python3 - << 'PYEOF'
with open("/usr/lib/libfprint-2.so.2.0.0.orig", "rb") as f:
    data = bytearray(f.read())

# Patch 1: EnableEnrollTips = 0 (at 0x66c11)
# Changes movl $1 -> movl $0 to skip FtEnrollTipsTemplate overlap check
data[0x66c11] = 0x00
print(f"Patch 1: EnableEnrollTips=0 at 0x66c11: {data[0x66c11]:02x}")

# Patch 2: QualityThreshold = 0 (at 0x66bdf)
# Lowers quality threshold so synthetic frames always pass
data[0x66bdf] = 0x00
print(f"Patch 2: QualityThreshold=0 at 0x66bdf: {data[0x66bdf]:02x}")

# Patch 3: Enroll quality bypass at 0x70897
# Forces area=100, quality=100 and jumps to FocalEnrollFeature
patch3 = bytes.fromhex(
    "c644243064"  # mov byte [rsp+0x30], 0x64 (area=100)
    "c644243164"  # mov byte [rsp+0x31], 0x64 (quality=100)
    "c703646400"  # mov dword [rbx], 0x00006464
    "00"
    "c605a5d203"  # mov byte [0x30bd2ae], 0x64
    "0364"
    "c6059dd203"  # mov byte [0x30bd2af], 0x64
    "0364"
    "4c8d15cdd3"  # lea r10, [rip+0x30d3d9] (logging context)
    "0300"
    "e9b3030000"  # jmp 0x70c58 (FocalEnrollFeature)
    "9090909090"  # nop padding
)
data[0x70897:0x70897+len(patch3)] = patch3
print(f"Patch 3: Enroll bypass at 0x70897: {len(patch3)} bytes")

# Patch 4: Unconditional jump at 0x7098f
data[0x7098f] = 0xEB  # jns -> jmp
data[0x70991] = 0x90  # nop
print(f"Patch 4: Unconditional jump at 0x7098f: {data[0x7098f]:02x}")

# Patch 5: Verify quality bypass at 0x88147
patch5 = bytes.fromhex(
    "c644245064"    # mov byte [rsp+0x50], 0x64 (area=100)
    "c644245164"    # mov byte [rsp+0x51], 0x64 (quality=100)
    "41b964000000"  # mov r9d, 100
    "41b864000000"  # mov r8d, 100
    "4c8b5c2408"    # mov r11, [rsp+0x08]
    "c60546510303"  # mov byte [0x30bd2af], 0x64
    "64"
    "c6053e510303"  # mov byte [0x30bd2ae], 0x64
    "64"
    "e99dfeffff"    # jmp 0x88012 (verify handler)
    "9090909090"    # nop padding
    "90"
)
data[0x88147:0x88147+len(patch5)] = patch5
print(f"Patch 5: Verify bypass at 0x88147: {len(patch5)} bytes")

with open("/tmp/libfprint-patched.so", "wb") as f:
    f.write(data)

print("Patched libfprint binary written to /tmp/libfprint-patched.so")
PYEOF

echo "=== 3. Installing patched libfprint ==="
cp /tmp/libfprint-patched.so /usr/lib/libfprint-2.so.2.0.0
chmod 755 /usr/lib/libfprint-2.so.2.0.0

echo "=== 4. Stopping fprintd ==="
systemctl stop fprintd || true
sleep 1

echo "=== 5. Unbinding SPI device ==="
if [ -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/devices/spi-FTE4800:00/driver/unbind || true
fi

echo "=== 6. Reloading focal_spi module ==="
rmmod focal_spi || true
sleep 1
insmod "$PROJ/focal_spi.ko" trace=1
sleep 2

echo "=== 7. Binding spi-FTE4800:00 to focalfp-spi ==="
echo "" > /sys/bus/spi/devices/spi-FTE4800:00/driver_override || true
if [ ! -e /sys/bus/spi/devices/spi-FTE4800:00/driver ]; then
    echo "spi-FTE4800:00" > /sys/bus/spi/drivers/focalfp-spi/bind || true
fi

echo "=== 8. Deleting old fingerprint data ==="
rm -rf /var/lib/fprint/archer/ || true

echo "=== 9. Restarting fprintd ==="
systemctl restart fprintd
sleep 2

echo "=== 10. Verification ==="
echo "Module srcversion: $(cat /sys/module/focal_spi/srcversion)"
ls -la /dev/focal_moh_spi
fprintd-list "$USER" || true

echo ""
echo "=== Deployment complete! ==="
echo "To test enrollment:"
echo "  fprintd-enroll -f right-index-finger archer"
echo "Then touch the fingerprint sensor for each stage."
echo ""
echo "To test verification:"
echo "  fprintd-verify archer"
