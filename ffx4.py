#!/usr/bin/env python3
"""ffx4.py - H: reset is ACTIVE-HIGH electrically (GPIO high = sensor held in reset). Evidence: with GPIO low INT line is high
(plausible boot-ready), with GPIO high INT is low and MISO only gives stale bytes.  Test Windows-exact boot with the line parked LOW.
POWER_OFF=0x8087 drives GPIO 0, POWER_ON=0x8088 drives GPIO 1. Run as root. Leaves GPIO HIGH (known state) at exit."""
import fcntl, os, sys, time, itertools
sys.path.insert(0, ".")
from ffx import xfer, DEV
fd = os.open(DEV, os.O_RDWR)
LOW, HIGH = 0x8087, 0x8088
WAKE = b"\xff\x00\x00\x00"
def gpio():
    s = {}
    for l in open("/sys/kernel/debug/gpio"):
        if "FPNT" in l: s["INT"] = l.rsplit(")",1)[1].split()[1]
        if "FTE4800" in l: s["RST"] = l.rsplit(")",1)[1].split()[1]
    return s
def rd(reg, n, m, hz, var):
    xfer(fd, [(WAKE, 0, 0)], m, hz); time.sleep(0.001)
    fr = bytes([reg, 0x80, n >> 8, n & 255, 0, 0, 0])
    if var == "held":  return xfer(fd, [(fr, 0, 200), (n, 0, 0)], m, hz)[1]
    if var == "2msg":
        xfer(fd, [(fr, 0, 0)], m, hz); return xfer(fd, [(n, 0, 0)], m, hz)[0]
    if var == "split": return xfer(fd, [(fr, 1, 0), (n, 0, 0)], m, hz)[1]
hits = 0
for how in ("park-low", "pulse-high-then-low"):
    for m, var, c55 in itertools.product((0, 3), ("held", "2msg", "split"), (True, False)):
        if how == "park-low": fcntl.ioctl(fd, LOW, 0)
        else:
            fcntl.ioctl(fd, HIGH, 0); time.sleep(0.01); fcntl.ioctl(fd, LOW, 0)
        time.sleep(0.5); g0 = gpio()
        if c55:
            xfer(fd, [(WAKE, 0, 0)], m, 1000000); time.sleep(0.001)
            xfer(fd, [(b"\x55\0\0\0", 0, 0)], m, 1000000); time.sleep(0.010)
        a = rd(0x90, 2, m, 1000000, var); b = rd(0x90, 2, m, 1000000, var); g1 = gpio()
        ok = b"\x56\xa2" in (a, b); hits += ok
        print(f"{how:20} mode={m} {var:5} cmd55={int(c55)} gpio {g0}->{g1} -> {a.hex()} {b.hex()}" + ("  <== 56A2 !!" if ok else "")); sys.stdout.flush()
fcntl.ioctl(fd, HIGH, 0)
print("done hits =", hits)
