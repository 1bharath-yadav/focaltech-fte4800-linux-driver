#!/usr/bin/env python3
import fcntl
import os
import sys
import time
sys.path.insert(0, "/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver")
from ffx import xfer, DEV
OFF, ON = 0x8087, 0x8088
fd=os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
try:
    fcntl.ioctl(fd, OFF, 0)
    print("power-off 100ms")
    time.sleep(0.1)
    fcntl.ioctl(fd, ON, 0)
    print("power-on; settling 1s")
    time.sleep(1.0)
    for hz in (1000000, 4000000):
        xfer(fd, [(b"\xff\x00\x00\x00",0,0)], 0, hz)
        time.sleep(0.005)
        fr=bytes.fromhex("91 80 00 20 00 00 00")+bytes(32)
        rx=xfer(fd, [(fr,0,0)], 0, hz)[0]
        d=rx[7:]
        print(f"hz={hz} data={d.hex(' ')} chip={d[19:21].hex(' ')}")
finally:
    fcntl.ioctl(fd, ON, 0)
    os.close(fd)
