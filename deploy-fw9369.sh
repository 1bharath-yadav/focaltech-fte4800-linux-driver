#!/bin/bash
set -e

echo "=== FocalTech FT9368 Driver Deployment ==="
echo "Changes:"
echo "  1. ChipID 0x9362 -> 0x9365 (fw9369 capture path)"
echo "  2. Restore original libfprint (remove synthetic-frame hacks)"
echo "  3. Clear old enrolled prints"
echo ""

# Step 1: Stop fprintd
echo ">>> Stopping fprintd..."
sudo systemctl stop fprintd.service 2>/dev/null || true
sleep 1

# Step 2: Restore original libfprint binary
echo ">>> Restoring original libfprint..."
if [ -f /usr/lib/libfprint-2.so.2.0.0.orig ]; then
    sudo cp /usr/lib/libfprint-2.so.2.0.0.orig /usr/lib/libfprint-2.so.2.0.0
    echo "    Restored from .orig backup"
else
    echo "    WARNING: No .orig backup found, keeping current binary"
fi

# Step 3: Remove old enrolled fingerprints (they were enrolled with synthetic frames)
echo ">>> Clearing old enrolled fingerprints..."
FPDIR="/var/lib/fprint"
if [ -d "$FPDIR" ]; then
    sudo find "$FPDIR" -type f -name "*.fp" -delete 2>/dev/null || true
    sudo find "$FPDIR" -type d -empty -delete 2>/dev/null || true
    echo "    Cleared $FPDIR"
else
    echo "    No fprint data directory found"
fi

# Step 4: Unload old module, load new one
echo ">>> Reloading kernel module..."
sudo rmmod focal_spi 2>/dev/null || true
sleep 0.5
sudo insmod /home/archer/projects/zerobook-focaltech-driver/focal_spi.ko trace=1
echo "    Module loaded"

# Step 5: Ensure spi-FTE4800:00 is bound to focalfp-spi
echo ">>> Checking device binding..."
SYSDEV="/sys/bus/spi/devices/spi-FTE4800:00"
if [ -d "$SYSDEV" ]; then
    CURRENT=$(cat "$SYSDEV/driver/uevent" 2>/dev/null | grep DRIVER_NAME | cut -d= -f2)
    if [ "$CURRENT" = "focalfp-spi" ]; then
        echo "    Already bound to focalfp-spi"
    else
        echo "    Rebinding to focalfp-spi..."
        echo "spi-FTE4800:00" | sudo tee /sys/bus/spi/drivers/spidev/unbind 2>/dev/null || true
        echo "" | sudo tee "$SYSDEV/driver_override" 2>/dev/null || true
        echo "spi-FTE4800:00" | sudo tee /sys/bus/spi/drivers/focalfp-spi/bind 2>/dev/null || true
        echo "    Rebound"
    fi
fi

# Step 6: Check /dev/focal_moh_spi exists
echo ">>> Checking device node..."
if [ -c /dev/focal_moh_spi ]; then
    echo "    /dev/focal_moh_spi exists"
else
    echo "    WARNING: /dev/focal_moh_spi missing!"
fi

# Step 7: Restart fprintd
echo ">>> Restarting fprintd..."
sudo systemctl restart fprintd.service
sleep 2

# Step 8: Verify
echo ""
echo "=== Verification ==="
echo ">>> Module srcversion:"
modinfo focal_spi.ko | grep srcversion
echo ">>> Chip ID in journal:"
sudo journalctl -u fprintd.service --no-pager -n 30 | grep -i "chipid\|9365\|9362\|fw93\|error\|Update_Base\|init\|width.*height" || echo "    (check manually)"
echo ""
echo ">>> dmesg (last 10 focal lines):"
dmesg | grep -i focal | tail -10

echo ""
echo "=== Deployment complete ==="
echo ""
echo "Next steps:"
echo "  1. fprintd-enroll \"\$USER\"    # Touch sensor 13 times with index finger"
echo "  2. fprintd-verify \"\$USER\"    # Touch with same finger -> should match"
echo "  3. fprintd-verify \"\$USER\"    # Touch with different finger -> should NOT match"
