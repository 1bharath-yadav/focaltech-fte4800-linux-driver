#!/usr/bin/env bash
set -u
ROOT="/home/archer/projects/zerobook-focaltech-driver"
AVDD="$ROOT/avdd-test/fte4800_avdd.ko"
MOD="$ROOT/focal_spi_reset-high.ko"
TEST="$ROOT/spi-direct-test/test_oem_postinit.py"
OLD=0
MASKED=0
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
systemctl stop fprintd.service 2>/dev/null || true
systemctl mask --runtime fprintd.service >/dev/null 2>&1 && MASKED=1
pkill -x fprintd 2>/dev/null || true
if lsmod | awk '{print $1}' | grep -qx focal_spi; then
  OLD=1
  rmmod focal_spi || exit 1
fi
echo "===== FORCE AVDD GPIO535 HIGH ====="
insmod "$AVDD" || exit 1
echo "===== LOAD RESET-HIGH DRIVER ====="
insmod "$MOD" || exit 1
echo "===== POST-HW INIT PROBE ====="
set +e
python3 "$TEST"
RC=$?
set -e
echo "TEST_RC=$RC"
echo "===== KERNEL LOG ====="
dmesg --color=never | grep -iE 'fte4800_avdd|FTE4800|focalfp-spi|reset:|spi.*error|transfer' | tail -180 || true
exit "$RC"
