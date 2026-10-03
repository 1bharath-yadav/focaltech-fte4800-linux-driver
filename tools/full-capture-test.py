#!/usr/bin/env python3
"""Full image capture with SFR(0x003B, 0x0001) — real sensor data confirmed!

SFR(0x003B, 0x0001) produced:
  ee ee ed de d2 b7 9d 68 51 39 33 30 28 35 38 32
This is a gradient from ~238 to ~40 — real capacitive fingerprint data!
"""
import ctypes
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
    libc.write(fd, ctypes.byref(buf), len(request))


def read_9368(fd, addr16, length):
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    return compat_read(fd, header, length)


def sfr_write(fd, addr16, value16):
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    val_hi = (value16 >> 8) & 0xFF
    val_lo = value16 & 0xFF
    compat_write(fd, bytes([0x70, 0x07, 0xF8, addr_hi, addr_lo, 0x00, 0x00, val_hi, val_lo, 0x00, 0x00]))


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # Reset and boot
        print("Resetting sensor...")
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)  # throwaway
        time.sleep(0.005)
        
        # Verify identity
        data = read_9368(fd, 0x9180, 32)
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"Chip ID: 0x{chip_id:04X} {'✓' if chip_id == 0x9368 else '✗'}")
        
        # Trigger capture mode
        print("\nSending SFR(0x003B, 0x0001)...")
        sfr_write(fd, 0x003B, 0x0001)
        time.sleep(0.100)
        
        # Read full image
        print("Reading 5120 bytes from 0x9080...")
        img = read_9368(fd, 0x9080, 5120)
        
        pixels = list(img)
        nonzero = sum(1 for p in pixels if p != 0)
        pmin, pmax = min(pixels), max(pixels)
        pmean = sum(pixels) / len(pixels)
        variance = sum((p - pmean)**2 for p in pixels) / len(pixels)
        std = variance ** 0.5
        unique = len(set(pixels))
        
        print(f"\n=== Image Statistics ===")
        print(f"  Size: {len(img)} bytes (64x80)")
        print(f"  Nonzero: {nonzero}/{len(img)} ({100*nonzero/len(img):.1f}%)")
        print(f"  Range: [{pmin}, {pmax}]")
        print(f"  Mean: {pmean:.1f}, Std: {std:.1f}")
        print(f"  Unique values: {unique}")
        
        print(f"\n  First 64 bytes (row 0):")
        print(f"    {img[:64].hex(' ')}")
        print(f"  Row 1:")
        print(f"    {img[64:128].hex(' ')}")
        print(f"  Row 2:")
        print(f"    {img[128:192].hex(' ')}")
        print(f"  Last row (79):")
        print(f"    {img[64*79:64*80].hex(' ')}")
        
        # Check for fingerprint-like structure:
        # - Should have variance (not flat)
        # - Should have spatial correlation (adjacent pixels similar)
        # - Values should span a reasonable range
        
        if variance > 100 and unique > 10:
            print("\n  ✓ Data appears to be real sensor image (high variance, many unique values)")
        elif unique <= 2:
            print("\n  ✗ Data appears to be pattern/calibration (too few unique values)")
        else:
            print(f"\n  ? Data quality unclear (variance={variance:.1f}, unique={unique})")
        
        # Save images
        with open("tools/real-capture.bin", "wb") as f:
            f.write(img)
        with open("tools/real-capture.pgm", "wb") as f:
            f.write(f"P5\n64 80\n255\n".encode())
            f.write(img[:5120])
        print(f"\n  Saved real-capture.bin and real-capture.pgm")
        
        # Do multiple captures to see if data changes
        print("\n=== Multiple captures (3x) ===")
        for i in range(3):
            libc.ioctl(fd, IOCTL_RESET, 0)
            time.sleep(0.400)
            _ = read_9368(fd, 0x9180, 2)
            sfr_write(fd, 0x003B, 0x0001)
            time.sleep(0.100)
            
            img = read_9368(fd, 0x9080, 5120)
            pixels = list(img)
            nonzero = sum(1 for p in pixels if p != 0)
            pmin, pmax = min(pixels), max(pixels)
            pmean = sum(pixels) / len(pixels)
            std_val = (sum((p-pmean)**2 for p in pixels) / len(pixels)) ** 0.5
            print(f"  Capture {i}: nonzero={nonzero} range=[{pmin},{pmax}] mean={pmean:.1f} std={std_val:.1f} first8={img[:8].hex(' ')}")
            
            with open(f"tools/capture-{i}.pgm", "wb") as f:
                f.write(f"P5\n64 80\n255\n".encode())
                f.write(img[:5120])
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
