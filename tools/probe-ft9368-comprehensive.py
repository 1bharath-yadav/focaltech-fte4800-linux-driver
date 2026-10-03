#!/usr/bin/env python3
"""Comprehensive FT9368 hardware validation after reset timing discovery.

PROVEN:
  - spi_write_then_read with 7-byte header [addr_hi, addr_lo, len_hi, len_lo, 0, 0, 0]
    returns real sensor data when the sensor is in application mode.
  - Sensor auto-boots from internal flash ~300ms after reset.
  - Chip ID 0x9368, firmware date 2022-07-29, 64x80 sensor.

NOW TESTING:
  1. Finger detection: wake + read 0x9180/6 → check for status 0x11
  2. Image capture: read 0x9080/5120 → raw pixel data
  3. ROM ID: read 0x90/2 after CMD_Set(0x55) in boot state
"""
import ctypes
import fcntl
import os
import struct
import sys
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
    """Use spi_write_then_read via the 0xA5 compat path."""
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
    """Write via the 0xA5 compat path."""
    tx_len = len(tx_bytes)
    request = bytearray(HEADER_SIZE + tx_len)
    struct.pack_into("<BHH", request, 0, SPI_READ_WRITE, tx_len, 0)
    request[HEADER_SIZE:HEADER_SIZE + tx_len] = tx_bytes
    buf = (ctypes.c_ubyte * len(request)).from_buffer_copy(bytes(request))
    result = libc.write(fd, ctypes.byref(buf), len(request))
    if result < 0:
        err = ctypes.get_errno()
        raise OSError(err, os.strerror(err))
    return result


def raw_xfer(fd, steps, mode=0xFFFFFFFF, speed_hz=1000000):
    """Execute raw SPI transfer via IOCTL_RAW_XFER."""
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


def read_9368(fd, addr16, length):
    """Read from FT9368 register using 7-byte header via spi_write_then_read."""
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    return compat_read(fd, header, length)


def write_9368(fd, addr16, data_bytes):
    """Write to FT9368 register. Header format TBD - try spi_write for now."""
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    length = len(data_bytes)
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    compat_write(fd, header + data_bytes)


def wake_9368(fd):
    """Send wake trigger: write [FF 00 00 00] to sensor."""
    compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        print("=" * 60)
        print("FT9368 Comprehensive Hardware Validation")
        print("=" * 60)
        
        # === Test 1: Identity Read ===
        print("\n--- Test 1: Identity Read (0x9180, 32) ---")
        data = read_9368(fd, 0x9180, 32)
        print(f"  RX: {data.hex(' ')}")
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"  Chip ID: 0x{chip_id:04X} {'✓ PASS' if chip_id == 0x9368 else '✗ FAIL'}")
        if len(data) >= 25:
            print(f"  FW date: {data[15]:02x}{data[16]:02x}-{data[17]:02x}-{data[18]:02x}")
            print(f"  Version: 0x{data[21]:02x}")
            print(f"  Manufacturer: 0x{data[22]:02x}")
            print(f"  Width: {data[23]}, Height: {data[24]}")
        
        # === Test 2: Finger Detection ===
        print("\n--- Test 2: Finger Detection (POA) ---")
        print("  Sending wake trigger (0xFF00)...")
        wake_9368(fd)
        time.sleep(0.005)
        
        status_data = read_9368(fd, 0x9180, 6)
        print(f"  Status (6 bytes): {status_data.hex(' ')}")
        if len(status_data) >= 4:
            # Check if first 4 bytes are identical (Windows driver validates this)
            if status_data[0] == status_data[1] == status_data[2] == status_data[3]:
                status_val = status_data[0]
                print(f"  Status byte: 0x{status_val:02X} (0x11 = finger present)")
                if status_val == 0x11:
                    print("  *** FINGER DETECTED ***")
                elif status_val == 0x00:
                    print("  No finger (idle)")
                else:
                    print(f"  Unknown status: 0x{status_val:02X}")
            else:
                print(f"  Status bytes NOT uniform: [{status_data[0]:02x} {status_data[1]:02x} {status_data[2]:02x} {status_data[3]:02x}]")
        
        # === Test 3: Image Capture ===
        print("\n--- Test 3: Image Capture (0x9080, 5120) ---")
        print("  Reading 5120 bytes from 0x9080...")
        img_data = read_9368(fd, 0x9080, 5120)
        print(f"  Received: {len(img_data)} bytes")
        
        if len(img_data) == 5120:
            # Statistics
            pixels = list(img_data)
            pmin = min(pixels)
            pmax = max(pixels)
            pmean = sum(pixels) / len(pixels)
            nonzero = sum(1 for p in pixels if p != 0)
            variance = sum((p - pmean) ** 2 for p in pixels) / len(pixels)
            
            print(f"  Min: {pmin}, Max: {pmax}, Mean: {pmean:.1f}")
            print(f"  Nonzero pixels: {nonzero}/{len(pixels)} ({100*nonzero/len(pixels):.1f}%)")
            print(f"  Variance: {variance:.1f}")
            print(f"  First 32 bytes: {img_data[:32].hex(' ')}")
            print(f"  Last 32 bytes:  {img_data[-32:].hex(' ')}")
            
            if variance > 10 and nonzero > 100:
                print("  ✓ Image data looks REAL (has variance and structure)")
            elif nonzero == 0:
                print("  ✗ Image data is all zeros")
            else:
                print(f"  ? Image data quality unclear")
            
            # Save raw image
            out_path = "tools/capture-raw.bin"
            with open(out_path, "wb") as f:
                f.write(img_data)
            print(f"  Saved to {out_path}")
            
            # Also save as PGM for viewing
            pgm_path = "tools/capture.pgm"
            with open(pgm_path, "wb") as f:
                f.write(f"P5\n64 80\n255\n".encode())
                f.write(img_data)
            print(f"  PGM image saved to {pgm_path}")
        
        # === Test 4: Reset + boot + identity verification ===
        print("\n--- Test 4: Reset → Boot → Re-read Identity ---")
        print("  Resetting sensor...")
        libc.ioctl(fd, IOCTL_RESET, 0)
        print("  Waiting 400ms for boot...")
        time.sleep(0.400)
        
        data = read_9368(fd, 0x9180, 32)
        chip_id2 = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"  Chip ID after reset: 0x{chip_id2:04X} {'✓ PASS' if chip_id2 == 0x9368 else '✗ FAIL'}")
        print(f"  RX: {data.hex(' ')}")
        
        # === Test 5: ROM ID (pre-firmware) ===
        print("\n--- Test 5: ROM ID Read in Boot State ---")
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.020)  # Short wait, sensor should be in ROM state
        
        # Try CMD_Set(0x55) + read ROM ID
        compat_write(fd, bytes([0x70, 0x55, 0xAA]))
        time.sleep(0.010)
        
        rom_data = read_9368(fd, 0x9080, 2)  # 0x90 with 0x80 flag
        rom_val = int.from_bytes(rom_data, 'big') if len(rom_data) >= 2 else 0
        print(f"  ROM ID (0x90/2): {rom_data.hex(' ')} = 0x{rom_val:04X} (expect 0x56A2)")
        
        # Wait for app mode and verify
        print("  Waiting for app mode (500ms)...")
        time.sleep(0.500)
        data = read_9368(fd, 0x9180, 32)
        chip_id3 = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"  App mode chip ID: 0x{chip_id3:04X} {'✓' if chip_id3 == 0x9368 else '✗'}")
        
        print("\n" + "=" * 60)
        print("SUMMARY")
        print("=" * 60)
        passed = sum([
            chip_id == 0x9368,
            chip_id2 == 0x9368,
            chip_id3 == 0x9368,
            len(img_data) == 5120,
        ])
        print(f"  Tests passed: {passed}/4")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
