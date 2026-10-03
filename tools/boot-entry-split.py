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
    time.sleep(0.02)
    xfer(fd, [(bytes.fromhex("55 00 00 00"),0,0)], 0, 1000000)
    time.sleep(0.010)
    tx=bytes.fromhex("04 fb 80 90 00 01")
    clock=bytes(2)
    for mode in (0, 3):
        out=xfer(fd, [(tx,0,0),(clock,0,0)], mode, 1000000)[0]
        print("mode",mode,"result",out.hex(" "))
        time.sleep(.1)
finally:
    os.close(fd)
