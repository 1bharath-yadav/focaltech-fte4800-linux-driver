#!/usr/bin/env python3
"""Test full-duplex image capture vs spi_write_then_read.

PROVEN: spi_write_then_read works for identity (0x9180, 32).
HYPOTHESIS: Image capture (0x9080) needs full-duplex single transfer
where TX = [header + N zeros] and RX = [7 dummy + N pixels] within one CS.

The AGENTS.md records a successful capture using this exact approach:
"Single full-duplex SPB transfer: TX: [0x90, 0x80, len_hi, len_lo, 0, 0, 0]
 + N zeros -> RX: 7 dummy bytes + N raw bytes"

Also test: does identity read work in full-duplex mode?
"""
import ctypes
import fcntl
import os
import struct
import time

DEV = "/dev/focal_moh_spi"
IOCTL_RESET = 0x8086
SPI_READ_WRITE = 0xA5
HEADER_SIZE = 5

IOC_RAW_XFER = 0x80A0
N_MAX = 16
BUF = 16384
SIZE = 16 + N_MAX * 8 + 2 * BUF
NOTX = 0x01
NORX = 0x02

libc = ctypes.CDLL(None, use_errno=True)
libc.read.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
libc.read.restype = ctypes.c_ssize_t
libc.ioctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong]
libc.ioctl.restype = ctypes.c_int


def compat_read(fd, tx_bytes, rx_len):
    tx_len = len(tx_bytes)
    request = bytearray(max(HEADER_SIZE + tx_len, rx_len))
    struct.pack_into("<BHH", request, 0, SPI_READ_WRITE, tx_len, rx_len)
    request[HEADER_SIZE:HEADER_SIZE + tx_len] = tx_bytes
    buf = (ctypes.c_ubyte * len(request)).from_buffer_copy(bytes(request))
    result = libc.read(fd, ctypes.byref(buf), len(request))
    if result < 0:
        err = ctypes.get_errno()
        raise OSError(err, os.strerror(err))
    return bytes(buf[:rx_len])


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


def full_duplex_read(fd, addr16, data_len):
    """Full-duplex: TX = [header + zeros], RX = [dummy + data]."""
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (data_len >> 8) & 0xFF
    len_lo = data_len & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    tx = header + bytes(data_len)
    results = raw_xfer(fd, [(tx, 0, 0, 0)])
    rx = results[0]
    return rx[7:]  # Skip 7-byte header echo region


def read_9368(fd, addr16, length):
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    return compat_read(fd, header, length)


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # Reset and wait for app mode
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)  # throwaway
        time.sleep(0.005)
        
        # Verify identity works
        data = read_9368(fd, 0x9180, 32)
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"Identity via WTR: 0x{chip_id:04X} {'✓' if chip_id == 0x9368 else '✗'}")
        
        # Test identity via full-duplex
        print("\n=== Full-duplex identity test ===")
        fd_data = full_duplex_read(fd, 0x9180, 32)
        fd_chip = (fd_data[19] << 8) | fd_data[20] if len(fd_data) >= 21 else 0
        print(f"  Full-duplex 0x9180/32: {fd_data.hex(' ')}")
        print(f"  Chip ID: 0x{fd_chip:04X} {'✓' if fd_chip == 0x9368 else '✗'}")
        
        # Test image via full-duplex (smaller sizes first)
        print("\n=== Full-duplex image capture test ===")
        for size in [8, 32, 64, 256, 1024, 5120]:
            data = full_duplex_read(fd, 0x9080, size)
            nonzero = sum(1 for b in data if b != 0)
            print(f"  FD 0x9080/{size:5d}: nonzero={nonzero:5d}/{size}")
            if nonzero > 0 and size <= 64:
                print(f"    Data: {data.hex(' ')}")
            elif nonzero > 0:
                pmin, pmax = min(data), max(data)
                pmean = sum(data) / len(data)
                print(f"    min={pmin} max={pmax} mean={pmean:.1f}")
                print(f"    First 32: {data[:32].hex(' ')}")
        
        # Test image via WTR (for comparison)
        print("\n=== WTR image capture test ===")
        for size in [8, 64, 5120]:
            data = read_9368(fd, 0x9080, size)
            nonzero = sum(1 for b in data if b != 0)
            print(f"  WTR 0x9080/{size:5d}: nonzero={nonzero:5d}/{size}")
            if nonzero > 0 and size <= 64:
                print(f"    Data: {data.hex(' ')}")
        
        # If full-duplex works for image, test with finger
        print("\n=== Finger touch detection (TOUCH THE SENSOR) ===")
        print("  Reading status in a loop for 10s...")
        print("  Place your finger on the sensor during this period.")
        t0 = time.monotonic()
        seen_finger = False
        while time.monotonic() - t0 < 10.0:
            status = read_9368(fd, 0x9180, 6)
            # Check for finger: all 4 bytes identical and == 0x11
            if len(status) >= 4:
                if status[0] == status[1] == status[2] == status[3] != 0:
                    elapsed = time.monotonic() - t0
                    if status[0] == 0x11:
                        print(f"  t={elapsed:.2f}s: FINGER DETECTED! status=0x{status[0]:02X}")
                        seen_finger = True
                    else:
                        print(f"  t={elapsed:.2f}s: status=0x{status[0]:02X} {status.hex(' ')}")
                elif any(b != 0 and b != 0xFF for b in status[:4]):
                    elapsed = time.monotonic() - t0
                    if status != b'\x00\x00\xff\x00\x00\x00':
                        print(f"  t={elapsed:.2f}s: non-zero status: {status.hex(' ')}")
            time.sleep(0.050)
        
        if not seen_finger:
            print("  No finger detection event in 10s")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
