#!/usr/bin/env python3
"""ffx3.py - H: sensor needs a turnaround gap between the 7-byte frame and the read within ONE CS window
(Windows issues write and read as two separate SPB calls under one lock). Expected: 56 A2 appears for some delay.
Windows-exact prefix each time: reset, settle, wake(FF000000)+1ms, CMD_Set(55), 10ms, wake+1ms, frame, [gap], read N. Run as root."""
import fcntl, os, sys, time, itertools
sys.path.insert(0, ".")
from ffx import xfer, DEV
fd = os.open(DEV, os.O_RDWR)
RESET = 0x8086
WAKE = b"\xff\x00\x00\x00"
out = open("ffx3-out.txt", "w"); hits = 0
def log(s):
    out.write(s + "\n"); out.flush()
for m, hz in ((0, 1000000), (3, 1000000), (0, 500000)):
    for gap in (0, 20, 100, 500, 2000, 10000, 50000):
        for n in (2, 4, 10):
            for use55 in (True, False):
                fcntl.ioctl(fd, RESET, 0); time.sleep(0.5)
                if use55:
                    xfer(fd, [(WAKE, 0, 0)], m, hz); time.sleep(0.001)
                    xfer(fd, [(b"\x55\0\0\0", 0, 0)], m, hz); time.sleep(0.010)
                xfer(fd, [(WAKE, 0, 0)], m, hz); time.sleep(0.001)
                fr = bytes([0x90, 0x80, 0, n, 0, 0, 0]) if False else bytes([0x90, 0x80, n >> 8, n & 255, 0, 0, 0])
                rx = xfer(fd, [(fr, 0, min(gap, 65535)), (n, 0, 0)], m, hz)[1]
                ok = b"\x56\xa2" in rx
                hits += ok
                l = f"mode={m} hz={hz:>7} gap={gap:>5}us n={n:>2} cmd55={int(use55)} -> {rx.hex()}" + ("  <== 56A2 !!" if ok else "")
                log(l)
                if ok: print(l); sys.stdout.flush()
print("done, hits =", hits)
from collections import Counter
print(Counter(l.split("-> ")[1].split("  <==")[0] for l in open("ffx3-out.txt")).most_common(14))
