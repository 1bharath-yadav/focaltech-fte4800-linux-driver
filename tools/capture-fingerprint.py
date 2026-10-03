#!/usr/bin/env python3
"""Capture fingerprint images with proper timing.

CONFIRMED:
- SFR(0x003B, 0x0001) triggers sensor capture
- After reset + 500ms boot + SFR write + 100ms, reading 0x9080/5120 returns
  real 8-bit capacitive sensor data (range 2-255, std ~34)
- Need to stabilize timing

Test plan:
1. Reset, boot (500ms), throwaway read
2. SFR(0x003B, 0x0001) — trigger capture  
3. Wait 200ms (give sensor time to scan)
4. Read 5120 bytes from 0x9080
5. Repeat with different delays to find optimal timing
6. Capture with and without finger for comparison
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
    return compat_read(fd, bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00]), length)


def sfr_write(fd, addr16, value16):
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    val_hi = (value16 >> 8) & 0xFF
    val_lo = value16 & 0xFF
    compat_write(fd, bytes([0x70, 0x07, 0xF8, addr_hi, addr_lo, 0x00, 0x00, val_hi, val_lo, 0x00, 0x00]))


def capture_frame(fd, delay_after_sfr=0.150):
    """Capture one frame: SFR trigger + delay + read."""
    sfr_write(fd, 0x003B, 0x0001)
    time.sleep(delay_after_sfr)
    return read_9368(fd, 0x9080, 5120)


def analyze_frame(img, label=""):
    pixels = list(img)
    nonzero = sum(1 for p in pixels if p != 0)
    if nonzero == 0:
        print(f"  {label}: ALL ZEROS")
        return False
    pmin, pmax = min(pixels), max(pixels)
    pmean = sum(pixels) / len(pixels)
    std = (sum((p - pmean)**2 for p in pixels) / len(pixels)) ** 0.5
    unique = len(set(pixels))
    is_real = std > 5 and unique > 5
    tag = "✓ REAL" if is_real else "✗ pattern"
    print(f"  {label}: range=[{pmin},{pmax}] mean={pmean:.1f} std={std:.1f} uniq={unique} {tag}")
    return is_real


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # === Step 1: Find optimal timing ===
        print("=== Timing sweep (no finger) ===")
        for delay in [0.050, 0.100, 0.150, 0.200, 0.300, 0.500]:
            libc.ioctl(fd, IOCTL_RESET, 0)
            time.sleep(0.500)
            _ = read_9368(fd, 0x9180, 2)
            time.sleep(0.005)
            
            img = capture_frame(fd, delay)
            analyze_frame(img, f"delay={delay:.3f}s")
        
        # === Step 2: Multiple captures without reset ===
        print("\n=== Repeated captures (no reset between) ===")
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)
        
        good_frames = []
        for i in range(10):
            img = capture_frame(fd, 0.200)
            is_real = analyze_frame(img, f"frame {i}")
            if is_real:
                good_frames.append((i, img))
        
        # Save the good frames
        if good_frames:
            for idx, (i, img) in enumerate(good_frames[:3]):
                path = f"tools/sensor-frame-{idx}.pgm"
                with open(path, "wb") as f:
                    f.write(f"P5\n64 80\n255\n".encode())
                    f.write(img[:5120])
                print(f"\n  Saved {path}")
                
                # Print ASCII visualization of the first frame
                if idx == 0:
                    print("\n  ASCII visualization (first frame, 64x40 = every other row):")
                    chars = " .:-=+*#%@"
                    for row in range(0, 80, 2):
                        line = ""
                        for col in range(0, 64, 1):
                            p = img[row * 64 + col]
                            ci = min(p * len(chars) // 256, len(chars) - 1)
                            line += chars[ci]
                        print(f"    {line}")
        
        print(f"\n  Good frames: {len(good_frames)}/10")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
