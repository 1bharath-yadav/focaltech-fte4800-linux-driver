#!/usr/bin/env python3
"""Exact Windows-protocol FT9368 probe using the raw IOCTL_RAW_XFER ioctl.

This script replicates the EXACT Windows DLL sequence for reading the chip
identity, based on confirmed disassembly of:
  - SPI0_Wakeup (0x18001bc48)
  - SPI0_Read_SPI bus-type-1 (0x18001b9ec)  
  - ft_feature_devinit_9368ReadChipID (0x18001c50c)
  - clsSpiDev::ft_interface_base_9368ReadData (0x180023290)
  - clsSpiDev::ft_interface_spi_RWDevData/SendControlTransferSynchronously (0x180025c2c)

Windows SPB backend facts (confirmed from disassembly):
  - State(0) / State(1) bracket each operation (maps to CS assertion on SPI)
  - Write and read backends use vtable+0x50/+0x58 with target 0x7bb7
  - RWDevData uses WdfIoTargetSendIoctlSynchronously with IOCTL 0x41814
    which is IOCTL_SPB_FULL_DUPLEX — a sequence of write+read within one CS

Wire-level protocol for 9368ReadData(addr16, len16):
  For len > 0:  TX = [addr_hi, addr_lo, len_hi, len_lo, 0, 0, 0]  (7 bytes)
  For len == 0: TX = [addr_hi, addr_lo, 0, 0]  (4 bytes, wake/trigger)
  Then RX = len bytes, within the same CS window (full-duplex sequence)

SPI0_Read_SPI(reg8, len16):
  TX = [reg, 0x80, len_hi, len_lo, 0, 0, 0]  (7 bytes, 0x80 hardcoded)
  Then RX = len bytes, same CS window

SPI0_Wakeup:
  State(0), write [FF 00 00 00], state(1)

Full read sequence (SPI0_Read_SPI bus type 1):
  1. SPI0_Wakeup
  2. Sleep 1ms
  3. State(0)
  4. Write 7-byte header
  5. Read N bytes
  6. State(1)

In Linux SPI terms:
  - SPI0_Wakeup = spi_write([FF 00 00 00]) as separate transaction
  - Sleep 1ms
  - Then spi_sync() with two transfers in one message:
    xfer[0]: tx_buf=header, len=7, cs_change=0  (keep CS held)
    xfer[1]: rx_buf=output, len=N, cs_change=0   (deassert CS after)

Must run as root.
"""
import fcntl
import os
import struct
import sys
import time

DEV = "/dev/focal_moh_spi"
IOC_RAW_XFER = 0x80A0
IOC_RESET = 0x8086

N_MAX = 16
BUF = 16384
SIZE = 16 + N_MAX * 8 + 2 * BUF
NOTX = 0x01
NORX = 0x02


def raw_xfer(fd, steps, mode=0xFFFFFFFF, speed_hz=0, pre_delay_us=0):
    """Execute raw SPI transfer via IOCTL_RAW_XFER.
    
    steps: list of (tx_bytes_or_rx_len, cs_change, delay_us, flags)
      tx_bytes: bytes to send (full-duplex)
      rx_len: int for rx-only transfer
    """
    buf = bytearray(SIZE)
    struct.pack_into("<IIII", buf, 0, len(steps), mode, speed_hz, pre_delay_us)
    
    offset = 0
    step_info = []
    for i, step in enumerate(steps):
        if len(step) == 4:
            data, cs_change, delay_us, flags = step
        elif len(step) == 3:
            data, cs_change, delay_us = step
            flags = 0
        else:
            raise ValueError(f"step {i}: expected 3 or 4 elements")
        
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


def spi_wakeup(fd, speed_hz=1000000):
    """Replicate SPI0_Wakeup: write [FF 00 00 00] as standalone transaction."""
    raw_xfer(fd, [(b"\xff\x00\x00\x00", 0, 0, NORX)], speed_hz=speed_hz)


def spi_read_9368(fd, addr16, length, speed_hz=1000000):
    """Replicate 9368ReadData: write header + read data in same CS window.
    
    Uses SPB-style sequence transfer (two spi_transfer in one spi_message).
    """
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    
    if length == 0:
        # 4-byte wake/trigger frame
        header = bytes([addr_hi, addr_lo, 0x00, 0x00])
    else:
        # 7-byte read header
        len_hi = (length >> 8) & 0xFF
        len_lo = length & 0xFF
        header = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00])
    
    if length == 0:
        # Write-only transaction
        raw_xfer(fd, [(header, 0, 0, NORX)], speed_hz=speed_hz)
        return b""
    
    # Two transfers in one CS window:
    # Transfer 0: TX header (no RX), keep CS held (cs_change=0 in multi-xfer)
    # Transfer 1: RX data (no TX)
    # In Linux SPI, multiple transfers in one spi_message share CS by default
    results = raw_xfer(fd, [
        (header, 0, 0, NORX),   # TX only, CS stays held
        (length, 0, 0, NOTX),   # RX only, CS deasserts after
    ], speed_hz=speed_hz)
    
    return results[1]  # Return RX data from second transfer


def spi_read_spi0(fd, reg8, length, speed_hz=1000000):
    """Replicate SPI0_Read_SPI: wakeup + sleep + header + read.
    
    This is the complete read sequence including wakeup.
    """
    # Step 1: Wakeup
    spi_wakeup(fd, speed_hz)
    
    # Step 2: Sleep 1ms
    time.sleep(0.001)
    
    # Step 3: Write header + Read data in same CS window
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    header = bytes([reg8, 0x80, len_hi, len_lo, 0x00, 0x00, 0x00])
    
    results = raw_xfer(fd, [
        (header, 0, 0, NORX),   # TX only
        (length, 0, 0, NOTX),   # RX only
    ], speed_hz=speed_hz)
    
    return results[1]


def test_rom_identity(fd, speed_hz=1000000):
    """Test ROM-state identity read: SPI0_Read_SPI(0x90, 2) -> expect 0x56A2."""
    print(f"\n=== ROM Identity Read (0x90, 2) at {speed_hz}Hz ===")
    data = spi_read_spi0(fd, 0x90, 2, speed_hz)
    print(f"  RX: {data.hex(' ')}")
    val = int.from_bytes(data, 'big') if len(data) >= 2 else 0
    print(f"  Value: 0x{val:04X} (expect 0x56A2)")
    return data


def test_app_identity(fd, speed_hz=1000000):
    """Test app-state chip ID read: ReadChipID sequence.
    
    1. 9368ReadData(0xFF00, 0) - wake trigger
    2. Sleep 5ms
    3. 9368ReadData(0x9180, 32) - read 32-byte descriptor
    4. Extract chip ID from bytes[19:21]
    """
    print(f"\n=== App Chip ID Read (9368ReadChipID) at {speed_hz}Hz ===")
    
    # Step 1: Wake trigger
    spi_wakeup(fd, speed_hz)
    time.sleep(0.001)
    spi_read_9368(fd, 0xFF00, 0, speed_hz)
    print("  Wake trigger (0xFF00, 0) sent")
    
    # Step 2: Sleep 5ms
    time.sleep(0.005)
    
    # Step 3: Read 32-byte descriptor
    spi_wakeup(fd, speed_hz)
    time.sleep(0.001)
    data = spi_read_9368(fd, 0x9180, 32, speed_hz)
    print(f"  RX (32 bytes): {data.hex(' ')}")
    
    if len(data) >= 21:
        chip_id = (data[19] << 8) | data[20]
        print(f"  Chip ID @19-20: 0x{chip_id:04X} (expect 0x9368)")
        if len(data) >= 23:
            print(f"  Version @21: 0x{data[21]:02X}")
            print(f"  Manufacturer @22: 0x{data[22]:02X}")
    
    return data


def test_full_duplex_read(fd, addr16, length, speed_hz=1000000):
    """Test with full-duplex single transfer (header + dummy bytes)."""
    addr_hi = (addr16 >> 8) & 0xFF
    addr_lo = addr16 & 0xFF
    len_hi = (length >> 8) & 0xFF
    len_lo = length & 0xFF
    
    # Full-duplex: send header + dummy bytes, read entire response
    tx = bytes([addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00]) + bytes(length)
    
    spi_wakeup(fd, speed_hz)
    time.sleep(0.001)
    
    results = raw_xfer(fd, [(tx, 0, 0)], speed_hz=speed_hz)
    data = results[0]
    print(f"  Full-duplex RX ({len(data)} bytes): {data.hex(' ')}")
    print(f"  Payload (after 7-byte header): {data[7:].hex(' ')}")
    return data[7:]  # Skip header echo


def main():
    if not os.path.exists(DEV):
        print(f"ERROR: {DEV} not found. Is focal_spi loaded?")
        return 1
    
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    try:
        # Reset sensor first
        print("Resetting sensor...")
        fcntl.ioctl(fd, IOC_RESET, 0)
        time.sleep(0.050)
        print("Reset complete.")
        
        speeds = [1000000]  # Start with ACPI-specified 1MHz
        
        for speed in speeds:
            print(f"\n{'='*60}")
            print(f"Testing at {speed}Hz")
            print(f"{'='*60}")
            
            # Test 1: ROM identity with full Windows sequence
            print("\n--- Method A: SPI0_Read_SPI (wakeup + split TX/RX) ---")
            test_rom_identity(fd, speed)
            
            # Test 2: ROM identity with full-duplex single transfer
            print("\n--- Method B: Full-duplex single transfer ---")
            spi_wakeup(fd, speed)
            time.sleep(0.001)
            test_full_duplex_read(fd, 0x9080 | 0x10, 2, speed)  # 0x90, 0x80 flag
            
            # Test 3: App chip ID sequence
            test_app_identity(fd, speed)
            
            # Test 4: Direct 0x9180 read without wake trigger
            print(f"\n--- Method C: Direct 0x9180 read (no wake trigger) ---")
            spi_wakeup(fd, speed)
            time.sleep(0.001)
            data = spi_read_9368(fd, 0x9180, 6, speed)
            print(f"  Direct 0x9180/6: {data.hex(' ')}")
            
            # Test 5: Try SPI0_Read_SPI with reg=0x91, which should
            # produce header [0x91, 0x80, 0, 32, 0, 0, 0] — same as
            # 9368ReadData(0x9180, 32) by coincidence
            print(f"\n--- Method D: SPI0_Read_SPI(0x91, 32) ---")
            data = spi_read_spi0(fd, 0x91, 32, speed)
            print(f"  SPI0_Read_SPI(0x91, 32): {data.hex(' ')}")
            if len(data) >= 21:
                chip_id = (data[19] << 8) | data[20]
                print(f"  Chip ID @19-20: 0x{chip_id:04X}")
        
        # Additional experiment: try the full boot entry sequence
        print(f"\n{'='*60}")
        print("Boot entry sequence test")
        print(f"{'='*60}")
        
        # Reset
        fcntl.ioctl(fd, IOC_RESET, 0)
        time.sleep(0.050)
        
        # CMD_Set(0x55) = [70 55 AA]
        print("Sending CMD_Set(0x55) = [70 55 AA]...")
        spi_wakeup(fd, 1000000)
        time.sleep(0.001)
        raw_xfer(fd, [(b"\x70\x55\xaa", 0, 0, NORX)], speed_hz=1000000)
        time.sleep(0.010)
        
        # Read 0x90 for ROM ID (0x56A2)
        print("Reading ROM ID (0x90, 2)...")
        data = spi_read_spi0(fd, 0x90, 2, 1000000)
        val = int.from_bytes(data, 'big') if len(data) >= 2 else 0
        print(f"  ROM ID: {data.hex(' ')} = 0x{val:04X} (expect 0x56A2)")
        
        return 0
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    sys.exit(main() or 0)
