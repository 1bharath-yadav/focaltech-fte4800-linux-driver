#!/usr/bin/env python3
import fcntl, os, struct, time
import numpy as np

DEV = '/dev/focal_moh_spi'
IOC_XFER = 0x80A0

def xfer(fd, steps, mode=0, hz=1000000):
    buf = bytearray(32912)
    struct.pack_into('<IIII', buf, 0, len(steps), mode, hz, 0)
    off = 0
    lens = []
    for i, (d, cs, dl) in enumerate(steps):
        n = len(d)
        buf[144 + off : 144 + off + n] = d
        struct.pack_into('<IHBB', buf, 16 + i * 8, n, dl, cs, 0)
        lens.append((off, n))
        off += n
    fcntl.ioctl(fd, IOC_XFER, buf, True)
    base = 144 + 16384
    return [bytes(buf[base + o : base + o + n]) for o, n in lens]

def get_frame(fd):
    xfer(fd, [(b'\xff\x00\x00\x00', 0, 0)])
    time.sleep(0.005)
    n = 10240
    fr = bytes([0x90, 0x80, (n >> 8) & 0xff, n & 0xff, 0, 0, 0]) + bytes(n)
    res = xfer(fd, [(fr, 0, 0)])[0]
    raw = res[7:]
    words = [((raw[i] << 8) | raw[i+1]) & 0x0FFC for i in range(0, 10240, 2)]
    return np.array(words, dtype=np.float64)

fd = os.open(DEV, os.O_RDWR)
print("Reading baseline frame 0 (no touch)...")
f0 = get_frame(fd)
print(f"Frame 0: mean={f0.mean():.1f}, std={f0.std():.1f}")

print("\nSampling 5 frames over 2 seconds...")
for i in range(1, 6):
    time.sleep(0.4)
    f = get_frame(fd)
    diff = np.abs(f - f0)
    print(f"Frame {i}: mean={f.mean():.1f}, std={f.std():.1f}, diff_from_f0={diff.mean():.1f}, max_diff={diff.max():.1f}")
