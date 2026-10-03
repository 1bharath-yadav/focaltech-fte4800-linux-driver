#!/usr/bin/env python3
"""Compare spi_write_then_read vs spi_sync split-TX/RX for FT9368 identity read.

The historical successful 93 68 read used the legacy driver's 0xA5 path which
calls spi_write_then_read(). This DEASSERTS CS between write and read.

This means the FT9368 might actually need SEPARATE CS windows for command
and response, NOT the held-CS behavior that SPI0_Read_SPI uses with Windows SPB.

Hypothesis: The sensor implements a command/response protocol where:
  1. CS assert → TX command → CS deassert  (sensor processes command)
  2. Brief pause 
  3. CS assert → RX response → CS deassert  (sensor sends response)

This is fundamentally different from the full-duplex or held-CS approach.

Test: Use the driver's 0xA5 read path (spi_write_then_read) to read identity.
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
libc.ioctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong]
libc.ioctl.restype = ctypes.c_int


def compat_read(fd, tx_bytes, rx_len):
    """Use the driver's 0xA5 read path (spi_write_then_read)."""
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


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # Test 1: Read identity using legacy 08 F7 command
        print("=== Using 0xA5 (spi_write_then_read) path ===")
        print()
        
        print("Test 1: Read 0x91 via 08 F7 91 00 (legacy identity)")
        data = compat_read(fd, bytes([0x08, 0xF7, 0x91, 0x00]), 32)
        print(f"  RX (32): {data.hex(' ')}")
        if len(data) >= 21:
            chip = (data[19] << 8) | data[20]
            print(f"  Chip ID @19-20: 0x{chip:04X}")
        print()
        
        print("Test 2: Read 0x90 via 08 F7 90 00 (ROM ID)")
        data = compat_read(fd, bytes([0x08, 0xF7, 0x90, 0x00]), 2)
        print(f"  RX (2): {data.hex(' ')} = 0x{int.from_bytes(data, 'big'):04X}")
        print()
        
        print("Test 3: Read 0x91 with 7-byte Windows header via 0xA5 path")
        # This sends [91 80 00 20 00 00 00] as TX, then reads 32 bytes
        data = compat_read(fd, bytes([0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00]), 32)
        print(f"  RX (32): {data.hex(' ')}")
        if len(data) >= 21:
            chip = (data[19] << 8) | data[20]
            print(f"  Chip ID @19-20: 0x{chip:04X}")
        print()
        
        # Reset and try again  
        print("=== After reset ===")
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.050)
        
        print("Test 4: Read 0x91 via 08 F7 91 00 (after reset)")
        data = compat_read(fd, bytes([0x08, 0xF7, 0x91, 0x00]), 32)
        print(f"  RX (32): {data.hex(' ')}")
        if len(data) >= 21:
            chip = (data[19] << 8) | data[20]
            print(f"  Chip ID @19-20: 0x{chip:04X}")
        print()
        
        print("Test 5: Read 0x90 via 08 F7 90 00 (after reset)")
        data = compat_read(fd, bytes([0x08, 0xF7, 0x90, 0x00]), 2)
        print(f"  RX (2): {data.hex(' ')} = 0x{int.from_bytes(data, 'big'):04X}")
        print()
        
        print("Test 6: Read with 7-byte header + separate read (after reset)")
        data = compat_read(fd, bytes([0x90, 0x80, 0x00, 0x02, 0x00, 0x00, 0x00]), 2)
        print(f"  RX (2): {data.hex(' ')} = 0x{int.from_bytes(data, 'big'):04X}")
        print()
        
        # Multiple rapid reads
        print("=== Multiple rapid 08 F7 91 00 reads ===")
        for i in range(5):
            data = compat_read(fd, bytes([0x08, 0xF7, 0x91, 0x00]), 32)
            nonzero = [(j, data[j]) for j in range(len(data)) if data[j] != 0]
            if nonzero:
                print(f"  Read {i}: {data.hex(' ')}")
                if len(data) >= 21:
                    chip = (data[19] << 8) | data[20]
                    print(f"           Chip ID: 0x{chip:04X}")
            else:
                print(f"  Read {i}: all zeros")
            time.sleep(0.010)
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
