#!/usr/bin/env python3
"""Test whether the split TX/RX with rx_buf=NULL causes CS issues on Intel LPSS.

The hypothesis is that when rx_buf is NULL on one transfer in a multi-transfer
message, the Intel LPSS pxa2xx-spi driver may handle CS differently (possibly
because it switches between PIO and DMA modes, or because it treats a TX-only
transfer as a separate transaction).

Also tests: what if both transfers are full-duplex (both have tx_buf and rx_buf)?
"""
import fcntl
import os
import struct
import time

DEV = "/dev/focal_moh_spi"
IOC_RAW_XFER = 0x80A0
IOC_RESET = 0x8086

N_MAX = 16
BUF = 16384
SIZE = 16 + N_MAX * 8 + 2 * BUF
NOTX = 0x01
NORX = 0x02


def raw_xfer(fd, steps, mode=0xFFFFFFFF, speed_hz=1000000):
    buf = bytearray(SIZE)
    struct.pack_into("<IIII", buf, 0, len(steps), mode, speed_hz, 0)
    offset = 0
    step_info = []
    for i, (data, cs_change, delay_us, flags) in enumerate(steps):
        if isinstance(data, int):
            length = data
            flags |= NOTX
        else:
            length = len(data)
            buf[16 + N_MAX * 8 + offset:16 + N_MAX * 8 + offset + length] = data
        struct.pack_into("<IHBB", buf, 16 + i * 8, length, delay_us, cs_change, flags)
        step_info.append((offset, length))
        offset += length
    fcntl.ioctl(fd, IOC_RAW_XFER, buf, True)
    rx_base = 16 + N_MAX * 8 + BUF
    return [bytes(buf[rx_base + off:rx_base + off + ln]) for off, ln in step_info]


def wakeup(fd):
    raw_xfer(fd, [(b"\xff\x00\x00\x00", 0, 0, NORX)])
    time.sleep(0.001)


hdr = bytes([0x90, 0x80, 0x00, 0x02, 0x00, 0x00, 0x00])

fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
try:
    fcntl.ioctl(fd, IOC_RESET, 0)
    time.sleep(0.050)
    
    print("=== Test A: Split TX/RX, TX has NORX flag ===")
    print("  (This is what we tried before - returns 00)")
    wakeup(fd)
    r = raw_xfer(fd, [
        (hdr, 0, 0, NORX),      # TX only, no RX capture
        (2, 0, 0, NOTX),        # RX only, no TX
    ])
    print(f"  xfer[0]: {r[0].hex(' ')}")
    print(f"  xfer[1]: {r[1].hex(' ')}")
    
    print("\n=== Test B: Split full-duplex, both have TX and RX ===")
    print("  (TX phase sends header, RX phase sends zeros, both read)")
    wakeup(fd)
    r = raw_xfer(fd, [
        (hdr, 0, 0, 0),          # Full duplex: send header, capture MISO
        (b"\x00\x00", 0, 0, 0),  # Full duplex: send zeros, capture MISO
    ])
    print(f"  xfer[0] ({len(r[0])}B): {r[0].hex(' ')}")
    print(f"  xfer[1] ({len(r[1])}B): {r[1].hex(' ')}")
    
    print("\n=== Test C: Like B but with inter-xfer delay ===")
    wakeup(fd)
    r = raw_xfer(fd, [
        (hdr, 0, 100, 0),        # Full duplex + 100us delay after
        (b"\x00\x00", 0, 0, 0),  # Full duplex
    ])
    print(f"  xfer[0] ({len(r[0])}B): {r[0].hex(' ')}")
    print(f"  xfer[1] ({len(r[1])}B): {r[1].hex(' ')}")
    
    print("\n=== Test D: Single full-duplex for comparison ===")
    wakeup(fd)
    r = raw_xfer(fd, [
        (hdr + b"\x00\x00", 0, 0, 0),  # All in one
    ])
    print(f"  xfer[0] ({len(r[0])}B): {r[0].hex(' ')}")
    print(f"  Bytes 7-8: {r[0][7:9].hex(' ')}")
    
    print("\n=== Test E: Large single full-duplex (7 + 32 bytes) ===")
    wakeup(fd)
    hdr32 = bytes([0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00])
    r = raw_xfer(fd, [
        (hdr32 + bytes(32), 0, 0, 0),
    ])
    rx = r[0]
    print(f"  xfer[0] ({len(rx)}B):")
    print(f"    Header echo: {rx[:7].hex(' ')}")
    print(f"    Data[0:16]:  {rx[7:23].hex(' ')}")
    print(f"    Data[16:32]: {rx[23:39].hex(' ')}")
    nonzero = [(i, rx[i]) for i in range(7, len(rx)) if rx[i] != 0]
    if nonzero:
        print(f"    Nonzero data bytes: {nonzero}")
    else:
        print(f"    All data bytes zero")
    
    print("\n=== Test F: Full boot sequence + full-duplex read ===")
    fcntl.ioctl(fd, IOC_RESET, 0)
    time.sleep(0.050)
    
    # CMD_Set(0x55)
    wakeup(fd)
    raw_xfer(fd, [(b"\x70\x55\xaa", 0, 0, NORX)])
    time.sleep(0.010)
    
    # SFR write 0x0004 = 0xAA55
    wakeup(fd)
    raw_xfer(fd, [(bytes([0x70, 0x07, 0xF8, 0x00, 0x04, 0x00, 0x00, 0xAA, 0x55, 0x00, 0x00]), 0, 0, NORX)])
    time.sleep(0.001)
    
    # SFR write 0x0048 = 0x0110
    wakeup(fd)
    raw_xfer(fd, [(bytes([0x70, 0x07, 0xF8, 0x00, 0x48, 0x00, 0x00, 0x01, 0x10, 0x00, 0x00]), 0, 0, NORX)])
    time.sleep(0.001)
    
    # Read ROM ID (0x90, 2) with full-duplex
    wakeup(fd)
    r = raw_xfer(fd, [
        (hdr + b"\x00\x00", 0, 0, 0),
    ])
    rx = r[0]
    print(f"  After CMD_Set(55) + SFR writes:")
    print(f"    Full RX: {rx.hex(' ')}")
    print(f"    Data[7:9]: {rx[7:9].hex(' ')} = 0x{int.from_bytes(rx[7:9], 'big'):04X} (expect 0x56A2)")
    
    print("\n=== Test G: Multiple read attempts after entry ===")
    for attempt in range(5):
        time.sleep(0.005)
        wakeup(fd)
        r = raw_xfer(fd, [(hdr + b"\x00\x00", 0, 0, 0)])
        rx = r[0]
        print(f"  Attempt {attempt}: {rx.hex(' ')} data[7:9]={rx[7:9].hex(' ')}=0x{int.from_bytes(rx[7:9], 'big'):04X}")
    
finally:
    os.close(fd)
