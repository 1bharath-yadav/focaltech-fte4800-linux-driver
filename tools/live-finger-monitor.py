#!/usr/bin/env python3
"""
Interactive Live Fingerprint Monitor for FT9368.
Continuously polls the sensor, detects finger touch, and prints an ASCII ridge map.
"""
import ctypes
import os
import struct
import time
import sys

DEV = "/dev/focal_moh_spi"
SPI_READ_WRITE = 0xA5
HEADER_SIZE = 5

libc = ctypes.CDLL(None, use_errno=True)
libc.read.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
libc.read.restype = ctypes.c_ssize_t

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
    return compat_read(fd, bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00]), length)

def render_ascii(img):
    # 64 width, 80 height; subsample rows by 2 for square aspect ratio in terminal
    chars = " .:-=+*#%@"
    lines = []
    for y in range(0, 80, 2):
        row = ""
        for x in range(0, 64):
            val = img[y * 64 + x]
            idx = min(val * len(chars) // 256, len(chars) - 1)
            row += chars[idx]
        lines.append(row)
    return "\n".join(lines)

def main():
    if os.geteuid() != 0:
        print("Please run with sudo: sudo python3 tools/live-finger-monitor.py")
        sys.exit(1)

    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        print("=" * 66)
        print(" FT9368 LIVE FINGERPRINT MONITOR — PLACE YOUR FINGER ON THE SENSOR")
        print("=" * 66)

        # Baseline reading
        print("Acquiring sensor stream...")
        frame_count = 0
        last_save = 0

        while frame_count < 15:
            time.sleep(0.15)
            img = read_9368(fd, 0x9080, 5120)
            if len(img) != 5120:
                continue

            pixels = list(img)
            pmin, pmax = min(pixels), max(pixels)
            pmean = sum(pixels) / len(pixels)
            std = (sum((p - pmean)**2 for p in pixels) / len(pixels)) ** 0.5
            uniq = len(set(pixels))

            # When finger is present, standard deviation and dynamic range increase significantly
            is_touch = std > 25 and uniq > 50

            state_str = "👉 FINGER DETECTED!" if is_touch else "   (idle / waiting) "
            print(f"\n[Frame {frame_count:02d}] {state_str} | Mean={pmean:.1f}, Std={std:.1f}, Range=[{pmin}, {pmax}], Unique={uniq}")

            if is_touch:
                print(render_ascii(img))
                # Save PGM
                with open(f"tools/live-touch-{frame_count}.pgm", "wb") as f:
                    f.write(f"P5\n64 80\n255\n".encode())
                    f.write(img)
                print(f"--> Saved frame to tools/live-touch-{frame_count}.pgm")

            frame_count += 1

    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
