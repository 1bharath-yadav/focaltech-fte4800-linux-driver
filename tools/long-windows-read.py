#!/usr/bin/env python3
import fcntl
import os
import sys
import time
sys.path.insert(0, "/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver")
from ffx import xfer, DEV, IOC_RESET
fd=os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
try:
    fcntl.ioctl(fd, IOC_RESET, 0)
    print("reset; settling 4 seconds...")
    sys.stdout.flush()
    time.sleep(4.0)
    for hz in (1000000, 4000000):
        xfer(fd, [(b"\xff\x00\x00\x00",0,0)], 0, hz)
        time.sleep(0.005)
        fr=bytes.fromhex("91 80 00 20 00 00 00")+bytes(32)
        rx=xfer(fd, [(fr,0,0)], 0, hz)[0]
        data=rx[7:]
        print(f"hz={hz} rx={data.hex(' ')} chip={data[19:21].hex(' ')}")
finally:
    os.close(fd)
