#!/usr/bin/env python3
"""After SFR_write(0x003B, 0x5401) (QUICK SENSOR MODE), image data appeared!

Now test:
1. Verify the image data is real sensor data (not echo)
2. Read full 5120 bytes 
3. Test finger presence in this mode
4. Try different SFR values to find the correct capture flow
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


def sfr_write(fd, addr16, value16):
    """SFR write: [70 07 F8 addr_hi addr_lo 00 00 val_hi val_lo 00 00]"""
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
        
        # Step 1: Switch to QUICK SENSOR MODE
        print("\n=== Switching to QUICK SENSOR MODE ===")
        sfr_write(fd, 0x003B, 0x5401)
        time.sleep(0.100)  # Give sensor time to process
        
        # Read image at various sizes
        print("\n--- Image reads after mode switch ---")
        for size in [16, 64, 256, 1024, 5120]:
            data = read_9368(fd, 0x9080, size)
            nonzero = sum(1 for b in data if b != 0)
            if nonzero > 0:
                pixels = list(data)
                pmin, pmax = min(pixels), max(pixels)
                pmean = sum(pixels) / len(pixels)
                uniq = len(set(pixels))
                print(f"  0x9080/{size:5d}: nonzero={nonzero:5d} min={pmin} max={pmax} mean={pmean:.1f} unique={uniq}")
                if size <= 64:
                    print(f"    Data: {data.hex(' ')}")
                else:
                    print(f"    First 32: {data[:32].hex(' ')}")
                    print(f"    Last 32:  {data[-32:].hex(' ')}")
            else:
                print(f"  0x9080/{size:5d}: all zeros")
        
        # Step 2: Try reading image with wake trigger first
        print("\n--- After wake + mode switch ---")
        compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))
        time.sleep(0.010)
        sfr_write(fd, 0x003B, 0x5401)
        time.sleep(0.100)
        
        data = read_9368(fd, 0x9080, 5120)
        nonzero = sum(1 for b in data if b != 0)
        if nonzero > 100:
            pixels = list(data)
            pmin, pmax = min(pixels), max(pixels)
            pmean = sum(pixels) / len(pixels)
            variance = sum((p - pmean)**2 for p in pixels) / len(pixels)
            print(f"  Image: {nonzero}/{len(data)} nonzero, min={pmin}, max={pmax}, mean={pmean:.1f}, var={variance:.1f}")
            print(f"  First 64: {data[:64].hex(' ')}")
            
            # Save raw image
            with open("tools/capture-mode-switch.bin", "wb") as f:
                f.write(data)
            with open("tools/capture-mode-switch.pgm", "wb") as f:
                f.write(f"P5\n64 80\n255\n".encode())
                f.write(data[:5120])
            print("  Saved capture-mode-switch.bin and .pgm")
        else:
            print(f"  Image: {nonzero} nonzero bytes (still mostly zeros)")
        
        # Step 3: Try SENSOR MODE (0x1F01) instead
        print("\n=== Trying SENSOR MODE (0x1F01) ===")
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)
        sfr_write(fd, 0x003B, 0x1F01)
        time.sleep(0.200)
        
        data = read_9368(fd, 0x9080, 5120)
        nonzero = sum(1 for b in data if b != 0)
        print(f"  Image 0x1F01: {nonzero} nonzero bytes")
        if nonzero > 0:
            print(f"  First 32: {data[:32].hex(' ')}")
        
        # Step 4: Sweep SFR values for register 0x003B
        print("\n=== SFR 0x003B value sweep ===")
        values = [0x1F01, 0x1F00, 0x5401, 0x5400, 0x2000, 0x2001, 
                  0x0001, 0x0100, 0x0101, 0xFF01, 0xFF00, 0x0054,
                  0x001F, 0x0020]
        for val in values:
            libc.ioctl(fd, IOCTL_RESET, 0)
            time.sleep(0.400)
            _ = read_9368(fd, 0x9180, 2)
            sfr_write(fd, 0x003B, val)
            time.sleep(0.100)
            data = read_9368(fd, 0x9080, 64)
            nonzero = sum(1 for b in data if b != 0)
            result = "ZEROS" if nonzero == 0 else f"DATA({nonzero}): {data[:16].hex(' ')}"
            print(f"  SFR(0x003B, 0x{val:04X}): {result}")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
