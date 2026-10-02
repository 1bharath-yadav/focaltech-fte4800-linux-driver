#!/usr/bin/env bash
set -u
ROOT="/home/archer/projects/zerobook-focaltech-driver"
AVDD="$ROOT/avdd-test/fte4800_avdd.ko"
MOD="$ROOT/focal_spi_reset-high.ko"
TEST="$ROOT/spi-direct-test/test_oem_sequence.py"
OLD=0
MASKED=0
AVDD_LOADED=0

restore() {
  set +e
  echo "===== RESTORE ====="
  rmmod focal_spi 2>/dev/null || true
  if [ "$OLD" -eq 1 ]; then modprobe focal_spi 2>/dev/null || true; fi
  rmmod fte4800_avdd 2>/dev/null || true
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
  OLD=1
  rmmod focal_spi || exit 1
fi

echo "===== FORCE AVDD GPIO535 HIGH ====="
insmod "$AVDD" || exit 1
AVDD_LOADED=1

echo "===== LOAD DIAGNOSTIC FOCAL DRIVER ====="
insmod "$MOD" || exit 1

echo "===== DRIVER / POWER LOG ====="
dmesg --color=never | grep -iE 'fte4800_avdd|FTE4800|focal|SPI config:|reset:' | tail -80 || true

echo "===== OEM STARTUP SEQUENCE ====="
set +e
python3 "$TEST"
RC=$?
set -e

echo "TEST_RC=$RC"
echo "===== FINAL KERNEL LOG ====="
dmesg --color=never | grep -iE 'fte4800_avdd|FTE4800|focal|SPI transaction|reset:|spi.*error|transfer' | tail -160 || true

exit "$RC"

