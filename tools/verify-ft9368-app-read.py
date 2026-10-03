#!/usr/bin/env python3
import os
import sys
sys.path.insert(0, "/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver/tools")
from fte4800_selftest import compat_read, reset_sensor

fd = os.open("/dev/focal_moh_spi", os.O_RDWR | os.O_CLOEXEC)
try:
    reset_sensor(fd)
    tx = bytes([0x08, 0xF7, 0x91, 0x00])
    data = compat_read(fd, tx, 32)
    print("FT9368-app-read raw:", data.hex(" "))
    print("len:", len(data))
    print("chip@0x13:", data[0x13:0x15].hex(" "))
    print("chip:", hex(int.from_bytes(data[0x13:0x15], "big")))
finally:
    os.close(fd)
