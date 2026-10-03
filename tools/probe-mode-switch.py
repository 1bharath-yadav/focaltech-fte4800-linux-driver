#!/usr/bin/env python3
"""Test FT9368 mode switch via register 0x3B writes.

From Windows RE of SwitchNextSensorWorkMode:
  Mode 1 (SENSOR MODE):  vtable[6](dl=0x3B, r8=0x1F, r9=1)
  Mode 2 (QUICK SENSOR): vtable[6](dl=0x3B, r8=0x54, r9=1)
  Mode 3 (PAO MODE):     vtable[6](dl=0x3B, r8=0x20, r9=0) + Sleep(1)
  Mode 4 (STOP MODE):    ...

vtable[6] might be writing to the sensor: addr=0x3B, data=[r8,r9]
or it could be a Windows driver ioctl with these params.

Since this is for ACPI (not USB), the call goes through a different path.
Let me test by writing these values to register 0x003B using the 7-byte header.

ALSO: The vtable[6] call in SwitchMode is to 0x180168c88->vtable[6], 
which is the same object as in state control. But here dl=0x3B not 0x79.
For bus_type=2 (ACPI), the state(0/1) with dl=0x79 is a no-op.
But this direct vtable[6] with dl=0x3B might NOT be a no-op for ACPI.

Alternative hypothesis: The vtable[6] dispatch function uses dl to select
the IOCTL type. dl=0x79 might be lock/unlock, dl=0x3B might be a 
register write command. Let me trace the actual vtable[6] implementation.
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
    """Write to FT9368 using 7-byte header format + data."""
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
        # Reset and boot
        libc.ioctl(fd, IOCTL_RESET, 0)
        time.sleep(0.500)
        _ = read_9368(fd, 0x9180, 2)  # throwaway
        time.sleep(0.005)
        
        # Verify identity
        data = read_9368(fd, 0x9180, 32)
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"Chip ID: 0x{chip_id:04X} {'✓' if chip_id == 0x9368 else '✗'}")
        
        # === Test sensor mode switch ===
        # The Windows RE shows dl=0x3B is used as a parameter to vtable[6].
        # For ACPI bus, vtable[6] might dispatch to a register write on the sensor.
        # Try writing to address 0x003B with mode values.
        
        print("\n=== Pre-mode-switch state ===")
        data = read_9368(fd, 0x9080, 16)
        print(f"  0x9080/16: {data.hex(' ')} (nonzero={sum(1 for b in data if b)})")
        
        # Test 1: Try writing mode command to 0x003B
        print("\n=== Test 1: Write SENSOR MODE (0x003B = [0x1F, 0x01]) ===")
        write_9368(fd, 0x003B, bytes([0x1F, 0x01]))
        time.sleep(0.050)
        
        # Check if image data is now available
        data = read_9368(fd, 0x9080, 32)
        nonzero = sum(1 for b in data if b != 0)
        print(f"  0x9080/32: {data.hex(' ')} (nonzero={nonzero})")
        
        # Check identity still works
        data = read_9368(fd, 0x9180, 32)
        chip_id = (data[19] << 8) | data[20] if len(data) >= 21 else 0
        print(f"  Identity: 0x{chip_id:04X}")

        # Test 2: Try PAO MODE (0x003B = [0x20, 0x00])
        print("\n=== Test 2: Write PAO MODE (0x003B = [0x20, 0x00]) ===")
        write_9368(fd, 0x003B, bytes([0x20, 0x00]))
        time.sleep(0.050)
        
        # Wake and check finger status
        compat_write(fd, bytes([0xFF, 0x00, 0x00, 0x00]))
        time.sleep(0.010)
        status = read_9368(fd, 0x9180, 6)
        print(f"  Status: {status.hex(' ')}")
        
        # Test 3: Try the write via different address encodings  
        # Maybe the mode command goes to address constructed from dl=0x3B:
        # 0x3B00, 0x003B, 0x9B00 (0x3B | 0x80 << 8)
        print("\n=== Test 3: Alternative mode addresses ===")
        for addr in [0x3B00, 0x9B80, 0x003B]:
            write_9368(fd, addr, bytes([0x1F, 0x01]))
            time.sleep(0.020)
            data = read_9368(fd, 0x9080, 16)
            nonzero = sum(1 for b in data if b != 0)
            print(f"  write(0x{addr:04X}, [1F 01]) → 0x9080/16 nonzero={nonzero}")
        
        # Test 4: Try SFR write format [70 07 F8 ...]
        # SFR_write(0x003B, value) → [70 07 F8 00 3B 00 00 val_hi val_lo 00 00]
        print("\n=== Test 4: SFR write mode command ===")
        for val_hi, val_lo in [(0x1F, 0x01), (0x54, 0x01), (0x20, 0x00)]:
            sfr = bytes([0x70, 0x07, 0xF8, 0x00, 0x3B, 0x00, 0x00, val_hi, val_lo, 0x00, 0x00])
            compat_write(fd, sfr)
            time.sleep(0.050)
            data = read_9368(fd, 0x9080, 16)
            nonzero = sum(1 for b in data if b != 0)
            data_id = read_9368(fd, 0x9180, 32)
            cid = (data_id[19] << 8) | data_id[20] if len(data_id) >= 21 else 0
            print(f"  SFR(0x003B, 0x{val_hi:02X}{val_lo:02X}): img_nonzero={nonzero} id=0x{cid:04X}")
        
        # Test 5: Read register 0x003B to see its value
        print("\n=== Test 5: Read various control registers ===")
        for addr in [0x003B, 0x3B00, 0x9B80]:
            data = read_9368(fd, addr, 4)
            print(f"  0x{addr:04X}: {data.hex(' ')}")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
