#!/usr/bin/env python3
import fcntl, os, struct, time

DEV = "/dev/focal_moh_spi"
IOC_XFER = 0x80A0

def xfer(fd, steps):
    buf = bytearray(32912)
    struct.pack_into("<IIII", buf, 0, len(steps), 0, 1000000, 0)
    off = 0
    lens = []
    for i, (d, cs, dl) in enumerate(steps):
        n = len(d)
        buf[144 + off : 144 + off + n] = d
        struct.pack_into("<IHBB", buf, 16 + i * 8, n, dl, cs, 0)
        lens.append((off, n))
        off += n
    fcntl.ioctl(fd, IOC_XFER, buf, True)
    base = 144 + 16384
    return [bytes(buf[base + o : base + o + n]) for o, n in lens]

def read_hw_raw(fd, n=5120):
    # Wake
    xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)])
    time.sleep(0.005)
    fr = bytes([0x90, 0x80, (n >> 8) & 0xff, n & 0xff, 0, 0, 0]) + bytes(n)
    res = xfer(fd, [(fr, 0, 0)])[0]
    return res[7:7+n]

fd = os.open(DEV, os.O_RDWR)
print("Reading Frame 1 (no touch)...")
f1 = read_hw_raw(fd, 5120)
print("Frame 1 first 32 bytes:", f1[:32].hex())

print("\nReading Frame 2 after 1 second (no touch)...")
time.sleep(1.0)
f2 = read_hw_raw(fd, 5120)
print("Frame 2 first 32 bytes:", f2[:32].hex())

diff_1_2 = sum(1 for a, b in zip(f1, f2) if a != b)
print(f"Differences between Frame 1 and Frame 2: {diff_1_2} / 5120 bytes")
