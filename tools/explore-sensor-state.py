#!/usr/bin/env python3
"""Explore FT9368 registers to understand sensor state and find capture mode.

The sensor is in application mode (firmware running, identity confirmed).
But image reads return zeros — the sensor needs mode-switch commands.

This script probes likely control/status registers based on Windows RE.
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


def compat_write(fd, tx_bytes):
    tx_len = len(tx_bytes)
    request = bytearray(HEADER_SIZE + tx_len)
    struct.pack_into("<BHH", request, 0, SPI_READ_WRITE, tx_len, 0)
    request[HEADER_SIZE:HEADER_SIZE + tx_len] = tx_bytes
    buf = (ctypes.c_ubyte * len(request)).from_buffer_copy(bytes(request))
    libc.write(fd, ctypes.byref(buf), len(request))


def read_9368(fd, addr16, length):
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    return compat_read(fd, header, length)


def write_9368(fd, addr16, data_bytes):
    """Write data to FT9368 register using 7-byte header + data."""
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    length = len(data_bytes)
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    compat_write(fd, header + data_bytes)


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # Reset, boot, throwaway
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)
        time.sleep(0.005)
        
        # Verify identity
        data = read_9368(fd, 0x9180, 32)
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"Chip ID: 0x{chip_id:04X} {'✓' if chip_id == 0x9368 else '✗'}")
        
        # Scan ALL 16-bit addresses in the 0x91xx range
        # The sensor uses 0x9180 for identity, other addresses may be control/status
        print("\n=== Register scan (0x9000 - 0x9FFF, 4 bytes each) ===")
        print("  Addresses returning non-trivial data (not all same byte):")
        for hi_nibble in range(0x90, 0xA0):
            for lo_nibble in range(0, 256, 4):
                addr = (hi_nibble << 8) | lo_nibble
                data = read_9368(fd, addr, 4)
                # Check for non-trivial (not all same byte, not all zero)
                if data and len(set(data)) > 1:
                    print(f"    0x{addr:04X}: {data.hex(' ')}")
        
        # Also check the 0xFFxx range (wake/control)
        print("\n=== Control register scan (0xFF00-0xFF3F) ===")
        for lo in range(0, 64, 4):
            addr = 0xFF00 | lo
            data = read_9368(fd, addr, 4)
            if data and len(set(data)) > 1:
                print(f"    0x{addr:04X}: {data.hex(' ')}")
        
        # Try SPI0_Read8 style reads (legacy 08 F7 commands)
        print("\n=== Legacy 8-bit register reads ===")
        for reg in [0x00, 0x01, 0x02, 0x04, 0x06, 0x09, 0x10, 0x40, 0x61, 
                    0x64, 0x6A, 0x80, 0x90, 0x91, 0xA0, 0xB0, 0xC0, 0xC6,
                    0xFD, 0xFE]:
            data = compat_read(fd, bytes([0x08, 0xF7, reg, 0x00]), 1)
            print(f"    reg 0x{reg:02X}: 0x{data[0]:02X}")
        
        # Try to trigger a scan/capture mode
        print("\n=== Attempting mode switch to capture ===")
        # Based on Windows RE, the sensor state machine uses these states:
        # State 4 or 9 = ready for capture
        # Need to find the switch command
        
        # Try writing mode values to various likely control registers
        # First, read current state
        print("  Reading status registers before mode switch:")
        for addr in [0x9100, 0x9200, 0x9300, 0x9400]:
            data = read_9368(fd, addr, 8)
            print(f"    0x{addr:04X}: {data.hex(' ')}")
        
        # Attempt wake + immediate image read  
        print("\n  Wake + capture attempt:")
        compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))  # wake
        time.sleep(0.010)
        
        # Read small samples at increasing offsets
        data = read_9368(fd, 0x9080, 32)
        nonzero = sum(1 for b in data if b != 0)
        print(f"    0x9080/32 after wake: nonzero={nonzero}")
        
        # Try 0x9000 (different from 0x9080)
        data = read_9368(fd, 0x9000, 32)
        nonzero = sum(1 for b in data if b != 0)
        print(f"    0x9000/32: nonzero={nonzero}")
        if nonzero:
            print(f"      Data: {data.hex(' ')}")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
