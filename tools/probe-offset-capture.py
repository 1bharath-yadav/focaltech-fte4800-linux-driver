#!/usr/bin/env python3
"""Verify the byte offset theory and test image capture.

Theory: The sensor needs 1 clock cycle after command to start producing valid
data. With spi_write_then_read, the first RX byte is residual/transition.
Solution: Request N+1 bytes and use bytes[1:N+1] as the actual data.

Also test: image capture with offset compensation.
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
    """Read from FT9368 with header length matching request."""
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    return compat_read(fd, header, length)


def read_9368_extra(fd, addr16, length, extra=1):
    """Read with extra bytes to compensate for offset, return data[extra:]."""
    total = length + extra
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (total >> 8) & 0xFF
    len_lo = total & 0xFF
    header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    data = compat_read(fd, header, total)
    return data[extra:]  # Skip the leading residual bytes


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # Reset and boot
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)  # throwaway
        time.sleep(0.005)

        # Test 1: Identity with extra bytes
        print("=== Test 1: Identity with offset compensation ===")
        for extra in [0, 1, 2, 3]:
            data = read_9368_extra(fd, 0x9180, 32, extra)
            chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
            print(f"  extra={extra}: chip=0x{chip_id:04X} first4=[{data[:4].hex(' ')}] {'✓' if chip_id == 0x9368 else ''}")
        
        # Test 2: Wake + status read with extra bytes
        print("\n=== Test 2: Status read with offset compensation ===")
        compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))
        time.sleep(0.010)
        
        for extra in [0, 1, 2, 3]:
            data = read_9368_extra(fd, 0x9180, 4, extra)
            status = f"uniform=0x{data[0]:02x}" if data[0]==data[1]==data[2]==data[3] else "not uniform"
            print(f"  extra={extra}: [{data[:4].hex(' ')}] {status}")
        
        # Test 3: Read raw status at different lengths
        print("\n=== Test 3: Raw status at different lengths ===")
        compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))
        time.sleep(0.010)
        for length in [2, 4, 6, 8, 10, 12, 16]:
            data = read_9368(fd, 0x9180, length)
            print(f"  read(0x9180, {length:2d}): {data.hex(' ')}")

        # Test 4: Image capture with extra bytes
        print("\n=== Test 4: Image capture test ===")
        
        # 4a: Small read from 0x9080
        print("  4a: Small reads from 0x9080:")
        for extra in [0, 1, 2]:
            data = read_9368_extra(fd, 0x9080, 16, extra)
            nonzero = sum(1 for b in data if b != 0)
            print(f"    extra={extra}: [{data[:16].hex(' ')}] nonzero={nonzero}")
        
        # 4b: Wake + image read
        print("  4b: After wake trigger + image read:")
        compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))
        time.sleep(0.010)
        for extra in [0, 1, 2]:
            data = read_9368_extra(fd, 0x9080, 64, extra)
            nonzero = sum(1 for b in data if b != 0)
            print(f"    extra={extra}: nonzero={nonzero}/{len(data)} first8=[{data[:8].hex(' ')}]")
        
        # 4c: Full 5120-byte image capture (64x80)
        print("  4c: Full 5120-byte image capture:")
        compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))
        time.sleep(0.010)
        data = read_9368(fd, 0x9080, 5121)  # +1 for offset
        img = data[1:]  # Skip first byte
        nonzero = sum(1 for b in img if b != 0)
        if nonzero > 100:
            pixels = list(img[:5120])
            pmin, pmax = min(pixels), max(pixels)
            pmean = sum(pixels) / len(pixels)
            print(f"    ✓ Got image data! nonzero={nonzero} min={pmin} max={pmax} mean={pmean:.1f}")
            print(f"    First 32: {img[:32].hex(' ')}")
            with open("tools/capture.pgm", "wb") as f:
                f.write(f"P5\n64 80\n255\n".encode())
                f.write(img[:5120])
            print("    Saved capture.pgm")
        else:
            print(f"    ✗ Image still zeros (nonzero={nonzero})")
            # Try without offset
            data = read_9368(fd, 0x9080, 5120)
            nonzero_raw = sum(1 for b in data if b != 0)
            print(f"    Without offset: nonzero={nonzero_raw}")
        
        # Test 5: Finger detection loop (5 seconds)
        print("\n=== Test 5: Finger detection (5s, touch sensor!) ===")
        t0 = time.monotonic()
        prev = None
        while time.monotonic() - t0 < 5.0:
            compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))
            time.sleep(0.010)
            # Read 5 bytes, use bytes[1:5] for status
            data = read_9368(fd, 0x9180, 5)
            status = data[1:5]  # compensate offset
            if status != prev:
                elapsed = time.monotonic() - t0
                uniform = status[0]==status[1]==status[2]==status[3]
                tag = ""
                if uniform and status[0] == 0x11:
                    tag = " *** FINGER ***"
                elif uniform and status[0] != 0:
                    tag = f" (uniform=0x{status[0]:02x})"
                print(f"  t={elapsed:.2f}s: raw={data.hex(' ')} status={status.hex(' ')}{tag}")
                prev = status
            time.sleep(0.040)
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
