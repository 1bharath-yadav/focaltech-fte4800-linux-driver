#!/usr/bin/env python3
"""ffx2.py - Windows-exact transaction (disassembly of fcn.18001bc48 / 0x18001b9ec):
   wake: [FF 00 00 00] in its own CS window -> sleep 1ms -> [reg 80 hi lo 00 00 00] + read N (one bracket).
   Boot: wake,1ms,CMD_Set(55)=[55 00 00 00]; sleep 10ms; wake,1ms; read 0x90 x2 -> expect 56 A2.  Run as root."""
import fcntl, os, sys, time, itertools
sys.path.insert(0, ".")
from ffx import xfer, DEV
RESET = 0x8086
fd = os.open(DEV, os.O_RDWR)
WAKE = b"\xff\x00\x00\x00"

def wake(m, hz, ms=1.0):
    xfer(fd, [(WAKE, 0, 0)], m, hz); time.sleep(ms / 1000)

def cmd_set(c, m, hz, wk=True):
    if wk: wake(m, hz)
    xfer(fd, [(bytes([c, 0, 0, 0]), 0, 0)], m, hz)

def rd(reg, n, m, hz, var, wk=True, wake_ms=1.0):
    if wk: wake(m, hz, wake_ms)
    fr = bytes([reg, 0x80, n >> 8, n & 255, 0, 0, 0])
    if var == "held":   return xfer(fd, [(fr, 0, 0), (n, 0, 0)], m, hz)[1]
    if var == "split":  return xfer(fd, [(fr, 1, 0), (n, 0, 0)], m, hz)[1]
    if var == "fd":     return xfer(fd, [(fr + bytes(n), 0, 0)], m, hz)[0][7:]
    if var == "2msg":
        xfer(fd, [(fr, 0, 0)], m, hz); return xfer(fd, [(n, 0, 0)], m, hz)[0]

hits, lines = [], []
for m, hz, var, settle, wk, cs55 in itertools.product((0, 3), (1000000, 4000000, 500000),
        ("held", "split", "fd", "2msg"), (0.1, 0.5), (True, False), (True, False)):
    fcntl.ioctl(fd, RESET, 0); time.sleep(settle)
    if cs55: cmd_set(0x55, m, hz, wk); time.sleep(0.010)
    a = rd(0x90, 2, m, hz, var, wk)
    b = rd(0x90, 2, m, hz, var, wk)
    ok = bytes([0x56, 0xA2]) in (a, b)
    l = f"mode={m} hz={hz:>7} {var:5} settle={settle} wake={int(wk)} cmd55={int(cs55)} -> {a.hex()} {b.hex()}" + ("  <== 56A2 !!" if ok else "")
    lines.append(l)
    if ok: hits.append(l); print(l); sys.stdout.flush()
open("ffx2-out.txt", "w").write("\n".join(lines) + "\n")
print(f"done: {len(lines)} runs, {len(hits)} hits")
from collections import Counter
print("distinct replies:", Counter(l.split("-> ")[1].split("  <==")[0] for l in lines).most_common(12))
