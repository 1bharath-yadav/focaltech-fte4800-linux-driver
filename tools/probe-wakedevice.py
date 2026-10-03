#!/usr/bin/env python3
"""Test exact Windows WakeDevice sequence.

WakeDevice at 0x18002d8a0:
  1. vtable[11](edx=0xFF00, r9=0) -> write [FF 00 00 00] 
  2. Sleep(10) -> 10ms
  3. ReadInfo(buf, 4) -> read 4 bytes from 0x9180
  4. Verify buf[0]==buf[1]==buf[2]==buf[3] and all non-zero
  5. Retry up to 3 times on failure

POADetectFingerPress at 0x18001C3F0:
  1. WakeDevice with wake arg 0xFF00
  2. Sleep(5)
  3. Read 6 bytes from 0x9180
  4. Check bytes[0:4] identical and == 0x11 for finger present
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


def wake_device(fd, retries=3):
    """Exact Windows WakeDevice sequence.
    
    Returns (success, status_byte) tuple.
    """
    for attempt in range(retries):
        # Step 1: Send wake trigger [FF 00 00 00] (4-byte header, 0-length read)
        # Using spi_write since length is 0
        compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))
        
        # Step 2: Sleep 10ms (Windows uses Sleep(10))
        time.sleep(0.010)
        
        # Step 3: Read 4 bytes from 0x9180
        status = read_9368(fd, 0x9180, 4)
        
        # Step 4: Verify all 4 bytes are identical and non-zero
        if (len(status) >= 4 and 
            status[0] != 0 and
            status[0] == status[1] == status[2] == status[3]):
            return True, status[0]
        
        print(f"  Wake attempt {attempt}: {status.hex(' ')} (not uniform/zero)")
    
    return False, 0


def detect_finger(fd):
    """Exact Windows POADetectFingerPress sequence.
    
    Returns (present, status_byte) tuple.
    """
    # Step 1: WakeDevice
    success, wake_status = wake_device(fd)
    if not success:
        return False, 0
    
    # Step 2: Sleep 5ms
    time.sleep(0.005)
    
    # Step 3: Read 6 bytes from 0x9180
    status = read_9368(fd, 0x9180, 6)
    
    # Step 4: Check bytes[0:4] identical and == 0x11
    if (len(status) >= 4 and
        status[0] == status[1] == status[2] == status[3]):
        return status[0] == 0x11, status[0]
    
    return False, 0


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # Ensure sensor is in app mode
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)  # throwaway
        
        # Verify identity
        data = read_9368(fd, 0x9180, 32)
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"Identity: 0x{chip_id:04X} {'✓' if chip_id == 0x9368 else '✗'}")
        
        # Test WakeDevice
        print("\n=== WakeDevice Test ===")
        success, status = wake_device(fd)
        print(f"WakeDevice result: success={success}, status=0x{status:02X}")
        
        # Test finger detection (10 polls)
        print("\n=== Finger Detection (10s, touch the sensor!) ===")
        t0 = time.monotonic()
        last_status = -1
        while time.monotonic() - t0 < 10.0:
            present, status = detect_finger(fd)
            if status != last_status:
                elapsed = time.monotonic() - t0
                if present:
                    print(f"  t={elapsed:.2f}s: FINGER PRESENT (0x{status:02X})")
                elif status != 0:
                    print(f"  t={elapsed:.2f}s: status=0x{status:02X} (no finger)")
                else:
                    print(f"  t={elapsed:.2f}s: wake failed or no uniform status")
                last_status = status
            time.sleep(0.050)
        
        print(f"\nFinal status: 0x{last_status:02X}")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
