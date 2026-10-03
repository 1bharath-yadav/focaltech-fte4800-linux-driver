#!/usr/bin/env python3
"""Deep hardware exploration with the confirmed working transport.

PROVEN: spi_write_then_read with 7-byte header works for identity reads.
First read after reset is a "throwaway" that clears shift register residue.

NOW: Explore more registers, finger detection, and image capture.
"""
import ctypes
import fcntl
import os
import struct
import time
import sys

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
    result = libc.write(fd, ctypes.byref(buf), len(request))
    if result < 0:
        err = ctypes.get_errno()
        raise OSError(err, os.strerror(err))


def read_9368(fd, addr16, length):
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    return compat_read(fd, header, length)


def write_9368_trigger(fd, addr16):
    """Send a 4-byte write trigger (0-length operation)."""
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    compat_write(fd, bytes([addr_hi, addr_lo, 0x00, 0x00]))


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # Ensure sensor is in app mode
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        # Throwaway read
        _ = read_9368(fd, 0x9180, 2)
        time.sleep(0.005)
        
        # Verify identity
        data = read_9368(fd, 0x9180, 32)
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"Identity: 0x{chip_id:04X} {'✓' if chip_id == 0x9368 else '✗'}")
        
        # === Finger Detection ===
        print("\n=== Finger Detection Tests ===")
        
        # Method 1: Wake trigger + read status
        print("\n  Method 1: Wake(0xFF00) + read(0x9180, 6)")
        write_9368_trigger(fd, 0xFF00)
        time.sleep(0.005)
        status = read_9368(fd, 0x9180, 6)
        print(f"    Status: {status.hex(' ')}")
        if all(b == status[0] for b in status[:4]):
            print(f"    Uniform status byte: 0x{status[0]:02X}")
        
        # Method 2: Direct status read without wake
        print("\n  Method 2: Direct read(0x9180, 6) no wake")
        status = read_9368(fd, 0x9180, 6)
        print(f"    Status: {status.hex(' ')}")
        
        # Method 3: Read different status registers
        print("\n  Method 3: Scan various registers")
        for addr in [0x9000, 0x9100, 0x9180, 0x9200, 0x9280, 0x9300, 0x9380]:
            data = read_9368(fd, addr, 4)
            nonzero = sum(1 for b in data if b != 0)
            if nonzero:
                print(f"    0x{addr:04X}: {data.hex(' ')} (nonzero={nonzero})")
        
        # === Image Capture ===
        print("\n=== Image Capture Tests ===")
        
        # Try smaller reads first
        for size in [8, 32, 64, 256, 1024]:
            data = read_9368(fd, 0x9080, size)
            nonzero = sum(1 for b in data if b != 0)
            first_nz = next((i for i, b in enumerate(data) if b != 0), -1)
            print(f"  0x9080/{size:5d}: nonzero={nonzero:4d} first_nz_at={first_nz}")
            if nonzero > 0:
                print(f"    First 16: {data[:16].hex(' ')}")
        
        # Try 0x9080 with a wake first
        print("\n  After wake trigger:")
        write_9368_trigger(fd, 0xFF00)
        time.sleep(0.010)
        for size in [8, 64, 5120]:
            data = read_9368(fd, 0x9080, size)
            nonzero = sum(1 for b in data if b != 0)
            print(f"  0x9080/{size:5d}: nonzero={nonzero:4d}")
            if nonzero > 0 and size <= 64:
                print(f"    Data: {data.hex(' ')}")
        
        # Try with the 06 F9 bulk format via spi_write_then_read
        print("\n  Bulk read via 06 F9 format:")
        bulk_hdr = bytes([0x06, 0xF9, 0x99, 0x05])
        data = compat_read(fd, bulk_hdr, 5120)
        nonzero = sum(1 for b in data if b != 0)
        print(f"  06 F9 99 05 / 5120: nonzero={nonzero}")
        if nonzero > 0:
            print(f"    First 32: {data[:32].hex(' ')}")
        
        # Try reading other potential image/data registers
        print("\n=== Exploring more registers ===")
        interesting = []
        for hi in range(0x90, 0xA0):
            for lo in [0x00, 0x80]:
                addr = (hi << 8) | lo
                data = read_9368(fd, addr, 4)
                nonzero = sum(1 for b in data if b != 0)
                if nonzero and data != bytes(4):
                    interesting.append((addr, data))
                    print(f"  0x{addr:04X}: {data.hex(' ')}")
        
        if not interesting:
            print("  No non-zero data found in 0x9000-0x9F80 range (read 4 bytes each)")
        
        # Check if we need to initiate a scan/capture first
        print("\n=== Write-based capture trigger test ===")
        # Try sending various capture-start commands
        # From Windows RE: state(0), wake, state(1), capture
        write_9368_trigger(fd, 0xFF00)
        time.sleep(0.005)
        
        # Read finger status
        status = read_9368(fd, 0x9180, 6)
        print(f"  Finger status: {status.hex(' ')}")
        
        # Try reading image
        img = read_9368(fd, 0x9080, 64)
        nonzero = sum(1 for b in img if b != 0)
        print(f"  Image 0x9080/64: nonzero={nonzero}")
        if nonzero:
            print(f"    {img.hex(' ')}")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
