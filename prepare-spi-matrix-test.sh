#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/projects/zerobook-focaltech-driver"
MATRIX="$ROOT/spi-matrix"
MOD_DIR="$ROOT/spi-direct-test"
mkdir -p "$MOD_DIR"

cat > "$MOD_DIR/test_register.py" <<'PY'
import ctypes
import os
import struct
import sys
import time

libc = ctypes.CDLL(None, use_errno=True)
fd = os.open("/dev/focal_moh_spi", os.O_RDWR | os.O_CLOEXEC)

def xioctl(cmd):
    rc = libc.ioctl(fd, ctypes.c_ulong(cmd), ctypes.c_ulong(0))
    if rc < 0:
        e = ctypes.get_errno()
        raise OSError(e, os.strerror(e))

def write_spi(data):
    raw = struct.pack("<BHH", 0xA5, 0, 0) + data
    buf = ctypes.create_string_buffer(raw, len(raw))
    n = libc.write(fd, ctypes.byref(buf), len(raw))
    if n < 0:
        e = ctypes.get_errno()
        raise OSError(e, os.strerror(e))
    return n

def read_spi(tx, rxlen):
    raw = struct.pack("<BHH", 0xA5, len(tx), rxlen) + tx
    buf = ctypes.create_string_buffer(raw, len(raw))
    n = libc.read(fd, ctypes.byref(buf), len(raw))
    if n < 0:
        e = ctypes.get_errno()
        raise OSError(e, os.strerror(e))
    return bytes(buf.raw[:n]), n

try:
    xioctl(0x8086)
    time.sleep(0.02)
    wn = write_spi(b"\x09\xf6\xc6\x01")
    time.sleep(0.004)
    rb, rn = read_spi(b"\x08\xf7\xc6\x00\x00", 1)
    value = rb[0] if rb else None
    print(f"write={wn} read={rn} response={value!r} hex={rb[:8].hex()}")
    sys.exit(0 if value == 1 else 2)
finally:
    os.close(fd)
PY

cat > "$MOD_DIR/run-matrix.sh" <<'INNER'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/projects/zerobook-focaltech-driver"
MATRIX="$ROOT/spi-matrix"
T="$ROOT/spi-direct-test/test_register.py"

echo "Stopping fprintd..."
systemctl stop fprintd.service 2>/dev/null || true
systemctl mask --runtime fprintd.service >/dev/null 2>&1 || true
pkill -x fprintd 2>/dev/null || true
sleep 1

for mode in 0 1 2 3; do
  echo "===== SPI MODE \${mode} @ 1 MHz ====="
  rmmod focal_spi 2>/dev/null || true
  insmod "$MATRIX/focal_spi_mode\${mode}.ko"
  sleep 0.15
  if python3 "$T"; then
    echo "RESULT mode\${mode}: PASS"
  else
    rc=$?
    echo "RESULT mode\${mode}: FAIL(rc=\${rc})"
  fi
  journalctl -k -b --no-pager -n 40 2>/dev/null |
    grep -Ei "focal|FTE4800|spi1" | tail -20 || true
done

echo "===== Restore MODE 0 ====="
rmmod focal_spi 2>/dev/null || true
insmod "$MATRIX/focal_spi_mode0.ko"
systemctl unmask fprintd.service >/dev/null 2>&1 || true
systemctl restart fprintd.service 2>/dev/null || true
echo "Done."
INNER

chmod +x "$MOD_DIR/run-matrix.sh"
echo "Created $MOD_DIR/run-matrix.sh"
echo "Run locally: sudo $MOD_DIR/run-matrix.sh"
