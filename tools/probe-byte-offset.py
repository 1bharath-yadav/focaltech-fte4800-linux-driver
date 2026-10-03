#!/usr/bin/env python3
"""Determine the exact byte offset in the SPI response.

Finding: Reading 4 bytes from 0x9180 returns [00 11 11 00] when finger is present.
Expected: [11 11 11 11].
Hypothesis: There's a 1-byte offset — the sensor prepends a dummy/status byte.

Test: Read different lengths and compare with known identity data to find the offset.
"""
import ctypes
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
libc.write.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
libc.write.restype = ctypes.c_ssize_t
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
        # Ensure sensor is in app mode
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)  # throwaway
        time.sleep(0.005)
        
        # Read identity at different lengths to find offset
        print("=== Identity read at different lengths ===")
        # Known identity (from 32-byte read):
        # 00 00 ff 00 00 00 00 00 00 00 00 5f 21 07 00 20 22 07 29 93 68 11 aa 40 50 00 00 00 00 00 00 00
        # Chip ID at bytes 19-20 = 93 68
        
        for length in [1, 2, 4, 6, 8, 16, 32, 33, 34]:
            data = read_9368(fd, 0x9180, length)
            print(f"  read(0x9180, {length:2d}): {data.hex(' ')}")
        
        print("\n=== Read with length+1 to capture offset ===")
        # If there's a 1-byte offset, reading 33 bytes should give us
        # a leading byte + the 32 real bytes
        data33 = read_9368(fd, 0x9180, 33)
        print(f"  read(0x9180, 33): {data33.hex(' ')}")
        
        data34 = read_9368(fd, 0x9180, 34)
        print(f"  read(0x9180, 34): {data34.hex(' ')}")
        
        # Read with the EXACT format the sensor expects (as per 9368ReadData)
        # But ask for len+1 to see if there's a leading byte
        print("\n=== Try reading with different header lengths ===")
        # Normal 7-byte header for 32 bytes
        data = compat_read(fd, bytes([0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00]), 32)
        print(f"  Normal hdr, rx=32: {data.hex(' ')}")
        
        # Same header but rx=33
        data = compat_read(fd, bytes([0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00]), 33)
        print(f"  Normal hdr, rx=33: {data.hex(' ')}")
        
        # Header says len=33 but rx=33
        data = compat_read(fd, bytes([0x91, 0x80, 0x00, 0x21, 0x00, 0x00, 0x00]), 33)
        print(f"  Hdr len=33, rx=33: {data.hex(' ')}")
        
        # Try reading with header specifying len+1 and requesting len+1
        # to see if the first byte is a status/dummy
        data = compat_read(fd, bytes([0x91, 0x80, 0x00, 0x05, 0x00, 0x00, 0x00]), 5)
        print(f"  Hdr len=5, rx=5:   {data.hex(' ')}")
        
        data = compat_read(fd, bytes([0x91, 0x80, 0x00, 0x06, 0x00, 0x00, 0x00]), 6)
        print(f"  Hdr len=6, rx=6:   {data.hex(' ')}")
        
        data = compat_read(fd, bytes([0x91, 0x80, 0x00, 0x07, 0x00, 0x00, 0x00]), 7)
        print(f"  Hdr len=7, rx=7:   {data.hex(' ')}")
        
        # Check if the identity data at 32-byte read is actually offset by 1
        # by looking at the expected chip ID position
        data32 = read_9368(fd, 0x9180, 32)
        data36 = read_9368(fd, 0x9180, 36)
        print(f"\n  32-byte: chipID@19-20 = {data32[19]:02x} {data32[20]:02x}")
        print(f"  36-byte: chipID@19-20 = {data36[19]:02x} {data36[20]:02x}")
        print(f"  36-byte: chipID@20-21 = {data36[20]:02x} {data36[21]:02x}")
        print(f"  36-byte: chipID@21-22 = {data36[21]:02x} {data36[22]:02x}")
        print(f"  36-byte full: {data36.hex(' ')}")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
