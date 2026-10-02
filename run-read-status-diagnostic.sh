#!/usr/bin/env bash
set -u
ROOT="/home/archer/projects/zerobook-focaltech-driver"
MOD="$ROOT/focal_spi.ko"
TEST="$ROOT/spi-direct-test/test_register.py"
WAS_LOADED=0
MASKED=0

restore() {
    set +e
    echo "===== RESTORE ====="
    rmmod focal_spi 2>/dev/null || true
    if [ "$WAS_LOADED" -eq 1 ]; then
        modprobe focal_spi 2>/dev/null || true
    fi
    if [ "$MASKED" -eq 1 ]; then
        systemctl unmask fprintd.service 2>/dev/null || true
        systemctl restart fprintd.service 2>/dev/null || true
    fi
}
trap restore EXIT

echo "Stopping fprintd..."
systemctl stop fprintd.service 2>/dev/null || true
systemctl mask --runtime fprintd.service >/dev/null 2>&1 && MASKED=1
pkill -x fprintd 2>/dev/null || true

if lsmod | awk '{print $1}' | grep -qx focal_spi; then
    WAS_LOADED=1
    rmmod focal_spi || exit 1
fi

echo "===== LOAD DIAGNOSTIC MODULE ====="
insmod "$MOD" || exit 1

echo "===== MODULE / GPIO STATE ====="
lsmod | grep '^focal_spi ' || true
dmesg --color=never | grep -iE 'focal|FTE4800|SPI config:|reset:' | tail -40 || true

echo "===== REGISTER TEST WITH TRUE SPI ERROR PROPAGATION ====="
set +e
python3 "$TEST"
RC=$?
set -e
echo "TEST_RC=$RC"

echo "===== NEW KERNEL LOG ====="
dmesg --color=never | grep -iE 'focal|FTE4800|SPI config:|reset:|SPI transaction|spi.*error|transfer' | tail -100 || true

exit "$RC"

