#!/usr/bin/env python3
import ctypes
import os
import time

DEV = "/dev/focal_moh_spi"
IOCTL_RESET = 0x8086
SPI_READ_WRITE = 0xA5

class Req(ctypes.Structure):
    _pack_ = 1
    _fields_ = [
        ("type", ctypes.c_uint8),
        ("tx_len", ctypes.c_uint16),
        ("rx_len", ctypes.c_uint16),
        ("data", ctypes.c_uint8 * 64),
    ]

libc = ctypes.CDLL(None, use_errno=True)

def fail_errno(op):
    e = ctypes.get_errno()
    raise OSError(e, f"{op}: {os.strerror(e)}")

def xioctl(fd, req):
    if libc.ioctl(fd, ctypes.c_ulong(req), ctypes.c_ulong(0)) < 0:
        fail_errno(f"ioctl 0x{req:x}")

def write_spi(fd, payload):
    # Driver ABI: packed header {u8 type; u16 tx_len; u16 rx_len;} + payload.
    raw = bytes((SPI_READ_WRITE,)) + len(payload).to_bytes(2, "little") + b"\x00\x00" + payload
    buf = ctypes.create_string_buffer(raw, len(raw))
    n = libc.write(fd, ctypes.byref(buf), len(raw))
    if n < 0:
        fail_errno("write")
    return n

def read_spi(fd, tx, rxlen):
    # Driver copies rd_buf[0:rxlen] back to the beginning of pUserBuf.
    raw = bytes((SPI_READ_WRITE,)) + len(tx).to_bytes(2, "little") + rxlen.to_bytes(2, "little") + tx
    buf = ctypes.create_string_buffer(raw, max(len(raw), rxlen))
    n = libc.read(fd, ctypes.byref(buf), len(raw))
    if n < 0:
        fail_errno("read")
    return bytes(buf.raw[:max(n, rxlen)]), n

def wr(fd, tag, payload, delay=0.0):
    n = write_spi(fd, payload)
    print(f"WRITE {tag:<14} n={n:2d} tx={payload.hex(' ')}")
    if n != 5 + len(payload):
        raise RuntimeError(f"short/invalid write: {n}/{5 + len(payload)}")
    if delay:
        time.sleep(delay)

def rd(fd, tag, tx, rxlen=1, delay=0.0):
    raw, n = read_spi(fd, tx, rxlen)
    rx = raw[:rxlen]
    print(f"READ  {tag:<14} n={n:2d} tx={tx.hex(' ')} rx={rx.hex(' ')}")
    if not rx:
        raise RuntimeError("no RX data")
    if delay:
        time.sleep(delay)
    return rx

fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)

print("=== FTE4800 OEM-init raw-sequence probe ===")
print(f"Device: {DEV}")
print()

xioctl(fd, IOCTL_RESET)
print("IOCTL_RESET ok")
time.sleep(0.020)

wr(fd, "WAKEUP1", bytes.fromhex("ff000000"), 0.020)
wr(fd, "MODE11",  bytes.fromhex("70"),        0.100)
wr(fd, "MODE0",   bytes.fromhex("c03f00"),     0.050)
wr(fd, "WAKEUP2", bytes.fromhex("ff000000"),  0.020)

s = rd(fd, "STATUS_80", bytes.fromhex("08f7800000"))[0]
print(f"STATUS = 0x{s:02x} (reference implementation expects 0x02)")

print()
print("=== Additional immediate probes ===")
for tag, tx in [
    ("READ_C6", bytes.fromhex("08f7c60000")),
    ("READ_9B", bytes.fromhex("08f79b0000")),
]:
    rd(fd, tag, tx)

os.close(fd)
