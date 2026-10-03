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
    time.sleep(0.020)
    xfer(fd, [(bytes.fromhex("ff 00 00 00"),0,0)], 0, 1000000)
    xfer(fd, [(bytes.fromhex("55 00 00 00"),0,0)], 0, 1000000)
    print("CMD_SET_55 sent")
    time.sleep(0.010)
    xfer(fd, [(bytes.fromhex("ff 00 00 00"),0,0)], 0, 1000000)
    tx=bytes.fromhex("90 80 00 02 00 00 00 00 00")
    rx=xfer(fd, [(tx,0,0)], 0, 1000000)[0]
    print("READ_SPI_90_2_TX="+tx.hex(" "))
    print("READ_SPI_90_2_RX="+rx.hex(" "))
    print("VALUE="+(hex((rx[7]<<8)|rx[8]) if len(rx)>=9 else "SHORT"))
finally:
    os.close(fd)
