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
    time.sleep(0.05)
    fcntl.ioctl(fd, ON, 0)
    print("power-released; exact historical settle 4s")
    sys.stdout.flush()
    time.sleep(4.0)
    wake=bytes.fromhex("ff 00 00 00")
    xfer(fd, [(wake,0,0)], 0, 1000000)
    time.sleep(0.005)
    fr=bytes.fromhex("91 80 00 20 00 00 00")+bytes(32)
    rx=xfer(fd, [(fr,0,0)], 0, 1000000)[0]
    data=rx[7:]
    print("rx=",data.hex(" "))
    print("chip=",data[19:21].hex(" "))
    for i in range(1,4):
        xfer(fd, [(wake,0,0)], 0, 1000000)
        time.sleep(0.005)
        data=xfer(fd, [(fr,0,0)], 0, 1000000)[0][7:]
        print("repeat",i,"chip=",data[19:21].hex(" "),"data=",data.hex(" "))
finally:
    fcntl.ioctl(fd, ON, 0)
    os.close(fd)
