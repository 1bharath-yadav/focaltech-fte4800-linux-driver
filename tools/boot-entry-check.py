#!/usr/bin/env python3
import fcntl
import os
import sys
import time
sys.path.insert(0, "/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver")
from ffx import xfer, DEV, IOC_RESET
fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
try:
    fcntl.ioctl(fd, IOC_RESET, 0)
    time.sleep(0.02)
    xfer(fd, [(bytes.fromhex("55 00 00 00"), 0, 0)], 0, 1000000)
    time.sleep(0.010)
    rx = xfer(fd, [(bytes.fromhex("04 fb 80 90 00 01"), 0, 0)], 0, 1000000)[0]
    print("RAW_RX=" + rx.hex(" "))
    print("PROBE=%s" % (hex((rx[0] << 8) | rx[1]) if len(rx) >= 2 else "SHORT"))
finally:
    os.close(fd)
