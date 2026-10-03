#!/usr/bin/env python3
"""Test sensor response timing after reset.

Key finding: Before reset, spi_write_then_read with 7-byte Windows header
[91 80 00 20 00 00 00] returns the real chip identity 0x9368.
After reset, it returns zeros.

Hypothesis: The sensor auto-loads firmware from internal flash after reset,
but needs time. Test reads at various intervals after reset.
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


def read_identity_7b(fd):
    """Read 32 bytes from 0x9180 using 7-byte Windows header."""
    return compat_read(fd, bytes([0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00]), 32)


def check_identity(data):
    """Check if the data contains the expected chip ID."""
    if len(data) >= 21:
        chip_id = (data[19] << 8) | data[20]
        nonzero = sum(1 for b in data if b != 0)
        return chip_id, nonzero
    return 0, 0


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # First verify pre-reset read works
        print("=== Pre-reset identity read ===")
        data = read_identity_7b(fd)
        chip, nz = check_identity(data)
        print(f"  RX: {data.hex(' ')}")
        print(f"  Chip ID: 0x{chip:04X}, nonzero bytes: {nz}")
        print()
        
        # Reset and poll at intervals
        print("=== Resetting sensor... ===")
        libc.ioctl(fd, IOCTL_RESET, 0)
        t0 = time.monotonic()
        
        # Poll at increasing intervals
        delays = [0.01, 0.02, 0.05, 0.1, 0.15, 0.2, 0.3, 0.5, 0.75, 
                  1.0, 1.5, 2.0, 3.0, 5.0, 8.0, 10.0, 15.0]
        
        prev_t = 0
        for target in delays:
            elapsed = time.monotonic() - t0
            wait = target - elapsed
            if wait > 0:
                time.sleep(wait)
            
            elapsed = time.monotonic() - t0
            data = read_identity_7b(fd)
            chip, nz = check_identity(data)
            
            status = "*** FOUND 0x9368 ***" if chip == 0x9368 else ""
            if nz > 0 and chip != 0x9368:
                status = f"nonzero={nz}"
            
            print(f"  t={elapsed:6.2f}s: chip=0x{chip:04X} [{data[:8].hex(' ')}...] {status}")
            
            if chip == 0x9368:
                print(f"\n  FULL DATA: {data.hex(' ')}")
                print(f"  Firmware date: {data[15]:02x}{data[16]:02x}-{data[17]:02x}-{data[18]:02x}")
                print(f"  Version: 0x{data[21]:02x}")
                print(f"  Width: {data[23]}, Height: {data[24]}")
                break
        else:
            print("\n  Chip ID 0x9368 NOT found within 15 seconds after reset.")
            print("  Last full response:", data.hex(' '))
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
