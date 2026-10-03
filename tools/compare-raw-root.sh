#!/usr/bin/env bash
set -euo pipefail
DEV="spi-FTE4800:00"
cleanup() {
  echo "$DEV" | sudo -n tee /sys/bus/spi/drivers/spidev/unbind >/dev/null 2>&1 || true
  sudo -n modprobe -r spidev >/dev/null 2>&1 || true
  echo "" | sudo -n tee "/sys/bus/spi/devices/$DEV/driver_override" >/dev/null 2>&1 || true
  sudo -n modprobe focal_spi >/dev/null 2>&1 || true
  echo "$DEV" | sudo -n tee /sys/bus/spi/drivers/focal-fte4800/bind >/dev/null 2>&1 || true
  sudo -n systemctl restart fprintd.service >/dev/null 2>&1 || true
}
trap cleanup EXIT

sudo -n systemctl stop fprintd.service || true
CURRENT="$(basename "$(readlink "/sys/bus/spi/devices/$DEV/driver" 2>/dev/null || true)")"
if [ -n "$CURRENT" ]; then
  echo "$DEV" | sudo -n tee "/sys/bus/spi/drivers/$CURRENT/unbind" >/dev/null
fi
sudo -n modprobe -r spidev >/dev/null 2>&1 || true
sudo -n modprobe spidev bufsiz=65536
echo spidev | sudo -n tee "/sys/bus/spi/devices/$DEV/driver_override" >/dev/null
echo "$DEV" | sudo -n tee /sys/bus/spi/drivers/spidev/bind >/dev/null
sleep 1

sudo -n python3 - <<'PY'
import ctypes, fcntl, os, struct, time

DEV="/dev/spidev1.0"
IOC_MSG=0x40206b00

class X(ctypes.Structure):
    _fields_=[("tx_buf",ctypes.c_uint64),("rx_buf",ctypes.c_uint64),
              ("len",ctypes.c_uint32),("speed_hz",ctypes.c_uint32),
              ("delay_usecs",ctypes.c_uint16),("bits_per_word",ctypes.c_uint8),
              ("cs_change",ctypes.c_uint8),("tx_nbits",ctypes.c_uint8),
              ("rx_nbits",ctypes.c_uint8),("word_delay_usecs",ctypes.c_uint8),
              ("pad",ctypes.c_uint8)]

libc=ctypes.CDLL(None,use_errno=True)
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
fcntl.ioctl(fd,0x40046b05,struct.pack("I",0))
fcntl.ioctl(fd,0x40046b04,struct.pack("I",1000000))

def msg(tx):
    a=(ctypes.c_ubyte*len(tx))(*tx)
    b=(ctypes.c_ubyte*len(tx))()
    x=X(); x.tx_buf=ctypes.addressof(a); x.rx_buf=ctypes.addressof(b)
    x.len=len(tx); x.speed_hz=1000000; x.bits_per_word=8
    if libc.ioctl(fd,IOC_MSG,x)<0:
        e=ctypes.get_errno(); raise OSError(e,os.strerror(e))
    return bytes(b)

msg(bytes([0xff,0,0,0]))
time.sleep(0.005)
info=msg(bytes([0x91,0x80,0,0x20,0,0,0])+bytes(0x20))
ip=info[7:39]
print("info:",ip.hex(" "))
img=msg(bytes([0x90,0x80,0x14,0x00,0,0,0])+bytes(0x1400))
p=img[7:7+0x1400]
print("image_len:",len(p),"min:",min(p),"max:",max(p),"unique:",len(set(p)))
print("first32:",p[:32].hex(" "))
os.close(fd)
PY
