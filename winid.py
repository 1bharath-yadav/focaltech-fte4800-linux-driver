#!/usr/bin/env python3
"""winid.py - replay the FIRST thing the Windows driver does at init (DLL fcn.18001c50c / 0x180021a04):
   wake [FF 00 00 00] (= 9368ReadData(0xff00,len0)); Sleep(5); then ONE full-duplex SPB transfer
   [91 80 00 20 00 00 00] + 32 zero bytes; chip ID = rx[0x13..0x14] of the 32 data bytes must be 93 68,
   rx[0x15] = version.  (Previous sweeps only tried reg 0x90 / 56A2 = ROM-bootloader ID; the app-mode
   ID block is reg 0x91.)  Hypothesis: sensor already runs app firmware and answers 0x91, not 0x90.
   Run as root: bash job6.sh"""
import fcntl, os, sys, time
sys.path.insert(0, ".")
from ffx import xfer, DEV, IOC_RESET
fd = os.open(DEV, os.O_RDWR)
WAKE = b"\xff\x00\x00\x00"

def rd(reg, n, m, hz, wake_ms):
    xfer(fd, [(WAKE, 0, 0)], m, hz); time.sleep(wake_ms / 1000)
    fr = bytes([reg, 0x80, n >> 8, n & 255, 0, 0, 0]) + bytes(n)
    return xfer(fd, [(fr, 0, 0)], m, hz)[0][7:]

hits = 0
for m, hz in ((0, 1000000), (3, 1000000), (0, 4000000)):
    for do_reset, settle in ((False, 0), (True, 0.05), (True, 0.4)):
        if do_reset:
            fcntl.ioctl(fd, IOC_RESET, 0); time.sleep(settle)
        for wms in (5.0, 1.0):
            a = rd(0x91, 0x20, m, hz, wms)
            b = rd(0x91, 6, m, hz, wms)
            c = rd(0x90, 2, m, hz, wms)
            ok = len(a) >= 0x15 and a[0x13] == 0x93 and a[0x14] == 0x68
            hits += ok
            print(f"mode={m} hz={hz//1000}k reset={int(do_reset)} settle={settle} wake_ms={wms} "
                  f"| 91/32: {a.hex()} | 91/6: {b.hex()} | 90/2: {c.hex()}" + ("  <== CHIP ID 9368 !!" if ok else ""))
            sys.stdout.flush()
print("hits:", hits)
