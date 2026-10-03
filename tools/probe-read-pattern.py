#!/usr/bin/env python3
"""Test the dummy-read-then-real-read pattern.

Hypothesis: After reset or after sending commands, the FT9368's SPI shift
register contains residue. A throwaway spi_write_then_read clears this,
and the subsequent read returns valid data.

The sensor needs: reset → wait 300+ms → dummy read → real read.
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
        print("=== Test: Reset → wait → multiple identity reads ===")
        print("Resetting...")
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.400)  # Wait for firmware boot
        
        for i in range(6):
            data = read_9368(fd, 0x9180, 32)
            chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
            tag = "*** 0x9368 ***" if chip_id == 0x9368 else ""
            print(f"  Read {i}: chip=0x{chip_id:04X} first8=[{data[:8].hex(' ')}] {tag}")
            time.sleep(0.005)
        
        print("\n=== Test: Reset → wait → different dummy read → identity ===")
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.400)
        
        # Dummy read with a short 1-byte request
        dummy = compat_read(fd, bytes([0x00]), 1)
        print(f"  Dummy read: {dummy.hex(' ')}")
        time.sleep(0.005)
        
        for i in range(3):
            data = read_9368(fd, 0x9180, 32)
            chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
            tag = "*** 0x9368 ***" if chip_id == 0x9368 else ""
            print(f"  Read {i}: chip=0x{chip_id:04X} first8=[{data[:8].hex(' ')}] {tag}")
            time.sleep(0.005)
        
        print("\n=== Test: Reset → long wait → reads ===")
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(1.0)  # Extra long wait
        
        for i in range(6):
            data = read_9368(fd, 0x9180, 32)
            chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
            tag = "*** 0x9368 ***" if chip_id == 0x9368 else ""
            print(f"  Read {i}: chip=0x{chip_id:04X} first8=[{data[:8].hex(' ')}] {tag}")
            if chip_id == 0x9368:
                print(f"    FULL: {data.hex(' ')}")
            time.sleep(0.005)
        
        print("\n=== Test: No reset, just read 10 times ===")
        for i in range(10):
            data = read_9368(fd, 0x9180, 32)
            chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
            tag = "*** 0x9368 ***" if chip_id == 0x9368 else ""
            print(f"  Read {i}: chip=0x{chip_id:04X} first8=[{data[:8].hex(' ')}] {tag}")
            if chip_id == 0x9368:
                print(f"    FULL: {data.hex(' ')}")
        
        print("\n=== Test: Image read (0x9080, 5120) ===")
        # First do an identity read to confirm good state
        data = read_9368(fd, 0x9180, 32)
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"  Pre-image identity: 0x{chip_id:04X}")
        
        img = read_9368(fd, 0x9080, 5120)
        nonzero = sum(1 for b in img if b != 0)
        if nonzero > 0:
            pmin = min(img)
            pmax = max(img)
            pmean = sum(img) / len(img)
            print(f"  Image: {len(img)} bytes, min={pmin}, max={pmax}, mean={pmean:.1f}")
            print(f"  Nonzero: {nonzero}/{len(img)}")
            print(f"  First 32: {img[:32].hex(' ')}")
        else:
            print(f"  Image: all zeros")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
