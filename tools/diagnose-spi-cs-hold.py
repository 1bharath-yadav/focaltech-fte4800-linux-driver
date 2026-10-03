#!/usr/bin/env python3
"""Diagnose SPI controller CS-hold behavior.

Tests several transfer configurations to understand how the Intel LPSS
SPI controller handles CS for multi-transfer messages.

Key hypothesis: Intel LPSS pxa2xx-spi may drop CS between transfers in 
the same spi_message, causing the sensor to lose framing.

Test approach:
  1. Single full-duplex transfer (TX header + dummy, RX entire response)
  2. Two transfers in same message (TX-only, RX-only)
  3. Two transfers with cs_change=1 on first (forces CS toggle)
  4. Single transfer with header + large RX
  5. Try with explicit inter-transfer delay

Also tests the effect of the wakeup byte positioning.
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


def raw_xfer(fd, steps, mode=0xFFFFFFFF, speed_hz=1000000, pre_delay_us=0):
    buf = bytearray(SIZE)
    struct.pack_into("<IIII", buf, 0, len(steps), mode, speed_hz, pre_delay_us)
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


def wakeup(fd):
    raw_xfer(fd, [(b"\xff\x00\x00\x00", 0, 0, NORX)])
    time.sleep(0.001)


def reset(fd):
    fcntl.ioctl(fd, IOC_RESET, 0)
    time.sleep(0.050)


def main():
    fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
    
    # Header for SPI0_Read_SPI(0x90, 2) = [90 80 00 02 00 00 00]
    hdr = bytes([0x90, 0x80, 0x00, 0x02, 0x00, 0x00, 0x00])
    read_len = 2
    
    tests = [
        # (name, steps_generator)
        ("T1: Full-duplex (hdr+dummy as one TX, full RX)", 
         lambda: [(hdr + bytes(read_len), 0, 0, 0)]),
        
        ("T2: Split TX/RX same message, no cs_change",
         lambda: [(hdr, 0, 0, NORX), (read_len, 0, 0, NOTX)]),
        
        ("T3: Split TX/RX same message, cs_change=1 on TX",
         lambda: [(hdr, 1, 0, NORX), (read_len, 0, 0, NOTX)]),
        
        ("T4: Full-duplex but with NORX on TX part",
         lambda: [(hdr, 0, 0, NORX), (read_len, 0, 0, NOTX)]),
        
        ("T5: Split with 100us delay between TX and RX",
         lambda: [(hdr, 0, 100, NORX), (read_len, 0, 0, NOTX)]),
         
        ("T6: Split with 1ms delay between TX and RX",
         lambda: [(hdr, 0, 1000, NORX), (read_len, 0, 0, NOTX)]),
        
        ("T7: Full-duplex 9 bytes, header in TX positions",
         lambda: [(hdr + b"\x00\x00", 0, 0, 0)]),
        
        ("T8: Full-duplex 11 bytes (extra clocking)",
         lambda: [(hdr + b"\x00\x00\x00\x00", 0, 0, 0)]),
        
        ("T9: Wakeup WITHIN same message, then read",
         lambda: [
             (b"\xff\x00\x00\x00", 0, 1000, NORX),  # wake + 1ms delay
             (hdr, 0, 0, NORX),   # TX header
             (read_len, 0, 0, NOTX),  # RX data
         ]),
        
        ("T10: All-in-one full-duplex (wake+header+read)",
         lambda: [(b"\xff\x00\x00\x00" + hdr + bytes(read_len), 0, 0, 0)]),
        
        ("T11: Separate wake msg, then split TX/RX msg",
         None),  # handled specially
        
        ("T12: CMD_Set(55) + read in one message",
         lambda: [
             (b"\x70\x55\xaa", 0, 0, NORX),  # CMD_Set
             (hdr, 0, 0, NORX),               # header
             (read_len, 0, 0, NOTX),           # read
         ]),
    ]
    
    try:
        reset(fd)
        
        for name, steps_gen in tests:
            if name.startswith("T11"):
                # Special: separate wake transaction, then separate read
                wakeup(fd)
                results = raw_xfer(fd, [
                    (hdr, 0, 0, NORX),
                    (read_len, 0, 0, NOTX),
                ])
                rx_parts = results
            else:
                wakeup(fd)
                steps = steps_gen()
                results = raw_xfer(fd, steps)
                rx_parts = results
            
            # Display results
            all_rx = b"".join(rx_parts)
            print(f"{name}")
            for j, part in enumerate(rx_parts):
                print(f"  xfer[{j}] ({len(part):3d}B): {part.hex(' ')}")
            
            # Check for 56A2 in any position
            if b"\x56\xa2" in all_rx:
                print(f"  *** FOUND 0x56A2! ***")
            print()
        
        # Also test with longer reads to see if data appears at different offsets
        print("=== Extended offset test ===")
        reset(fd)
        for extra in [0, 2, 4, 8, 16, 32]:
            wakeup(fd)
            total = 7 + read_len + extra
            tx = hdr + bytes(read_len + extra)
            results = raw_xfer(fd, [(tx, 0, 0, 0)])
            rx = results[0]
            nonzero = [i for i, b in enumerate(rx) if b != 0]
            nz_summary = f"nonzero@{nonzero}" if nonzero else "all-zeros"
            print(f"  Full-duplex {total:3d}B: {rx.hex(' ')} ({nz_summary})")
        
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
