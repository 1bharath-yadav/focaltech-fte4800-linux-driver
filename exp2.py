#!/usr/bin/env python3
"""exp2.py - does MISO content depend on the sensor at all?  Run as root.
H: if the repeating 0a/0e/14 stream is identical with RESET held low, the sensor is not the source
   (unpowered/not responding); if it differs, the sensor logic is alive and framing is the issue."""
import fcntl, os, time, sys
sys.path.insert(0, ".")
from ffx import xfer, DEV
POWER_OFF, POWER_ON, RESET = 0x8087, 0x8088, 0x8086   # POWER_OFF = reset line LOW, POWER_ON = HIGH
fd = os.open(DEV, os.O_RDWR)
F = bytes([0x90, 0x80, 0, 2, 0, 0, 0])
def probe(tag):
    out = []
    for mode in (0, 1, 3):
        for tx in (F, b"\x00" * 7, b"\xff" * 7):
            out.append(f"m{mode}:{xfer(fd,[(tx,0,0)],mode,1000000)[0].hex()}")
    print(f"{tag:<28}", " ".join(out)); sys.stdout.flush()
def gpio():
    for l in open("/sys/kernel/debug/gpio"):
        if "FPNT" in l or "FTE4800" in l: print("   ", l.strip())
gpio()
fcntl.ioctl(fd, POWER_OFF, 0); time.sleep(0.05); probe("RESET LOW (held)"); gpio()
fcntl.ioctl(fd, POWER_ON, 0);  probe("reset released +0ms")
time.sleep(0.1);               probe("+100ms")
time.sleep(1.0);               probe("+1.1s")
time.sleep(3.0);               probe("+4s"); gpio()
print("IRQ line in /proc/interrupts:")
os.system("grep -i focal /proc/interrupts")
