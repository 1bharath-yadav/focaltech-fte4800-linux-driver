#!/usr/bin/env python3
import fcntl, os, struct, sys, time

DEV = "/dev/focal_moh_spi"
IOC_XFER = 0x80A0
N_XFER = 16
BUF_SIZE = 16384
TOTAL_SIZE = 16 + N_XFER * 8 + 2 * BUF_SIZE

def xfer(fd, steps, mode=0, hz=1000000, pre=0):
    buf = bytearray(TOTAL_SIZE)
    struct.pack_into("<IIII", buf, 0, len(steps), mode, hz, pre)
    off = 0
    lens = []
    for i, (d, cs, dl) in enumerate(steps):
        n = len(d)
        buf[144 + off : 144 + off + n] = d
        struct.pack_into("<IHBB", buf, 16 + i * 8, n, dl, cs, 0)
        lens.append((off, n))
        off += n
    fcntl.ioctl(fd, IOC_XFER, buf, True)
    base = 144 + BUF_SIZE
    return [bytes(buf[base + o : base + o + n]) for o, n in lens]

def wake(fd):
    xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)])
    time.sleep(0.005)

def reg_read(fd, reg, n):
    wake(fd)
    fr = bytes([reg, 0x80, (n >> 8) & 0xff, n & 0xff, 0, 0, 0]) + bytes(n)
    res = xfer(fd, [(fr, 0, 0)])[0]
    return res[7:]

def reg_write8(fd, reg, val):
    # Pattern 1 write: 09 F6 reg val
    fr = bytes([0x09, 0xF6, reg, val])
    xfer(fd, [(fr, 0, 0)])

def reg_read8(fd, reg):
    wake(fd)
    fr = bytes([0x08, 0xF7, reg, 0x00, 0x00])
    res = xfer(fd, [(fr, 0, 0)])[0]
    return res[4] if len(res) >= 5 else 0

def reg_write16(fd, addr, val):
    # Pattern 2 write: 05 FA addr_hi|0x80 addr_lo count_hi count_lo val_hi val_lo
    addr_hi = ((addr >> 8) & 0x7f) | 0x80
    addr_lo = addr & 0xff
    fr = bytes([0x05, 0xFA, addr_hi, addr_lo, 0x00, 0x01, (val >> 8) & 0xff, val & 0xff])
    xfer(fd, [(fr, 0, 0)])

def reg_read16(fd, addr):
    addr_hi = ((addr >> 8) & 0x7f) | 0x80
    addr_lo = addr & 0xff
    fr = bytes([0x04, 0xFB, addr_hi, addr_lo, 0x00, 0x01, 0x00, 0x00])
    res = xfer(fd, [(fr, 0, 0)])[0]
    if len(res) >= 8:
        return (res[6] << 8) | res[7]
    return 0

fd = os.open(DEV, os.O_RDWR)
print("=== Step 1: Check App ID ===")
wake(fd)
app_id = reg_read(fd, 0x91, 0x20)
print(f"App ID response: {app_id.hex()}")
if len(app_id) >= 0x15:
    print(f"Firmware: {app_id[0x0f:0x13].hex()}, Chip: {app_id[0x13:0x15].hex()} (FT{app_id[0x13]:02x}{app_id[0x14]:02x})")
    print(f"Resolution: {app_id[0x17]} x {app_id[0x18]}")

print("\n=== Step 2: Arm Scan Engine ===")
reg_write16(fd, 0x1A84, 0xFFFF)
xfer(fd, [(bytes([0x5A, 0xA5, 0x00]), 0, 0)])
time.sleep(0.003)
st80 = reg_read8(fd, 0x80)
print(f"Status reg 0x80: 0x{st80:02x}")
xfer(fd, [(bytes([0xA5, 0x5A, 0x00]), 0, 0)])
time.sleep(0.005)
reg_write16(fd, 0x1801, 0xFC80)
reg_write16(fd, 0x1800, 0x4FFE)
print("Arming complete.")

print("\n=== Step 3: Start Scan Mode ===")
xfer(fd, [(bytes([0xC4, 0x3B, 0x00]), 0, 0)])
time.sleep(0.001)
for i in range(10):
    s = reg_read8(fd, 0x80)
    print(f"Poll 0x80 attempt {i}: 0x{s:02x}")
    if s == 0x54:
        break

print("\n=== Step 4: Trigger Exposure ===")
reg_write16(fd, 0x1800, 0x4FFF)
time.sleep(0.010)

int_st = reg_read16(fd, 0x1A82)
print(f"Interrupt Status 0x1A82: 0x{int_st:04x} (bit 5 = {int_st & 0x0020})")

print("\n=== Step 5: Read FIFO (10240 bytes) ===")
# 5120 words = 0x1400 words
fifo_cmd = bytes([0x06, 0xF9, 0x9A, 0x05, 0x14, 0x00]) + bytes(10240)
res = xfer(fd, [(fifo_cmd, 0, 0)])[0]
dummy = res[:6]
pixels_raw = res[6:6+10240]

print(f"Echo/dummy bytes: {dummy.hex()}")
print(f"Pixels raw len: {len(pixels_raw)}")
print(f"First 32 bytes: {pixels_raw[:32].hex()}")
print(f"Middle 32 bytes: {pixels_raw[5120:5152].hex()}")
print(f"Last 32 bytes: {pixels_raw[-32:].hex()}")

non_zero = sum(1 for b in pixels_raw if b != 0)
unique_bytes = len(set(pixels_raw))
print(f"Non-zero bytes: {non_zero} / {len(pixels_raw)}")
print(f"Unique byte values: {unique_bytes}")

print("\n=== Step 6: Acknowledge & Idle ===")
reg_write16(fd, 0x1A84, 0x0020)
xfer(fd, [(bytes([0xC0, 0x3F, 0x00]), 0, 0)])
print("Done.")
