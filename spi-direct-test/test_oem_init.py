#!/usr/bin/env python3
import ctypes
import os
import time

DEV = "/dev/focal_moh_spi"
IOCTL_RESET = 0x8086
SPI_READ_WRITE = 0xA5
libc = ctypes.CDLL(None, use_errno=True)

def fail_errno(op):
    e = ctypes.get_errno()
    raise OSError(e, f"{op}: {os.strerror(e)}")

def ioctl_reset(fd):
    if libc.ioctl(fd, ctypes.c_ulong(IOCTL_RESET), ctypes.c_ulong(0)) < 0:
        fail_errno("ioctl reset")

def write_spi(fd, tx):
    raw = bytes((SPI_READ_WRITE,)) + len(tx).to_bytes(2, "little") + b"\x00\x00" + tx
    buf = ctypes.create_string_buffer(raw, len(raw))
    n = libc.write(fd, ctypes.byref(buf), len(raw))
    if n < 0:
        fail_errno("write")
    if n != len(raw):
        raise RuntimeError(f"short write: {n}/{len(raw)}")
    return n

def read_spi(fd, tx, rxlen):
    raw = bytes((SPI_READ_WRITE,)) + len(tx).to_bytes(2, "little") + rxlen.to_bytes(2, "little") + tx
    buf = ctypes.create_string_buffer(raw, len(raw))
    n = libc.read(fd, ctypes.byref(buf), len(raw))
    if n < 0:
        fail_errno("read")
    if n != len(raw):
        raise RuntimeError(f"short read: {n}/{len(raw)}")
    return bytes(buf.raw[:rxlen])

def wr(fd, tag, tx, delay=0.0):
    n = write_spi(fd, tx)
    print(f"WRITE {tag:<18} n={n:2d} tx={tx.hex(' ')}")
    if delay:
        time.sleep(delay)

def rd(fd, tag, tx, rxlen=1, delay=0.0):
    rx = read_spi(fd, tx, rxlen)
    print(f"READ  {tag:<18} n={5 + len(tx):2d} tx={tx.hex(' ')} rx={rx.hex(' ')}")
    if delay:
        time.sleep(delay)
    return rx

def mode(fd, name, cmd, delay=0.005):
    wr(fd, name, bytes((cmd, (~cmd) & 0xff, 0x00)), delay)

def wr8(fd, reg, val, delay=0.002):
    wr(fd, f"WR8 {reg:02X}={val:02X}", bytes((0x09, 0xF6, reg, val)), delay)

def rd8(fd, reg, delay=0.002):
    return rd(fd, f"RD8 {reg:04X}", bytes((0x08, 0xF7, reg, 0x00, 0x00)), 1, delay)[0]

def wr16(fd, addr, val, delay=0.002):
    tx = bytes((0x05, 0xFA, (addr >> 8) | 0x80, addr & 0xff, 0, 1, (val >> 8) & 0xff, val & 0xff))
    wr(fd, f"WR16 {addr:04X}={val:04X}", tx, delay)

def rd16(fd, addr, delay=0.002):
    tx = bytes((0x04, 0xFB, ((addr >> 8) & 0xff) | 0x80, addr & 0xff, 0, 1))
    rx = rd(fd, f"RD16 {addr:04X}", tx, 2, delay)
    return (rx[0] << 8) | rx[1]

fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
try:
    print("=== FTE4800 pre-hw + PLL + chip-ID probe ===")
    ioctl_reset(fd)
    print("IOCTL_RESET ok")
    time.sleep(0.020)

    wr(fd, "WAKEUP1", bytes.fromhex("ff000000"), 0.020)
    wr(fd, "MODE11 RESET", bytes.fromhex("70"), 0.100)
    wr(fd, "MODE0 IDLE", bytes.fromhex("c03f00"), 0.050)
    wr(fd, "WAKEUP2", bytes.fromhex("ff000000"), 0.010)

    s = rd8(fd, 0x80, 0.002)
    print(f"STATUS initial = 0x{s:02X}")

    print("\n--- pre_hw_init: mode9 -> status -> mode0(if needed) -> mode10 ---")
    mode(fd, "MODE9 FDT-DOWN", 0x5A, 0.005)
    s9 = rd8(fd, 0x80, 0.002)
    print(f"STATUS after MODE9 = 0x{s9:02X}")
    if s9 != 0x50:
        mode(fd, "MODE0 FORCE", 0xC0, 0.050)
    mode(fd, "MODE10 FDT-UP", 0xA5, 0.010)
    s10 = rd8(fd, 0x80, 0.002)
    print(f"STATUS after MODE10 = 0x{s10:02X}")

    print("\n--- PLL calibration sequence: SPI_InitRegs(0x03) ---")
    wr8(fd, 0xF1, 0x03)
    for v in (0xC0, 0xC1, 0xC0, 0xC0):
        wr8(fd, 0xF4, v, 0.004)
    cal_a = rd8(fd, 0xF3, 0.004)
    print(f"CAL F3 after gain=03 = 0x{cal_a:02X}")

    print("\n--- PLL calibration sequence: SPI_InitRegs(0x13) ---")
    wr8(fd, 0xF1, 0x13)
    for v in (0xC0, 0xC1, 0xC0, 0xC0):
        wr8(fd, 0xF4, v, 0.004)
    cal_b = rd8(fd, 0xF3, 0.004)
    print(f"CAL F3 after gain=13 = 0x{cal_b:02X}")

    print("\n--- identity ---")
    chip = rd16(fd, 0x85C0, 0.004)
    alt = rd16(fd, 0x1A8B, 0.004)
    status = rd8(fd, 0x80, 0.002)
    print(f"CHIP ID 0x85C0 = 0x{chip:04X}  (reference expects 0x9369)")
    print(f"ALT  ID 0x1A8B = 0x{alt:04X}  (reference expects 0x9362)")
    print(f"FINAL STATUS   = 0x{status:02X}")

    print("\n--- volatile startup config (only after identity read) ---")
    wr16(fd, 0x1A84, 0xFFFF, 0.004)
    wr16(fd, 0x1800, 0x4FFE, 0.004)
    print("PROBE_RC=0")
finally:
    os.close(fd)
