#!/usr/bin/env python3
"""diagnose_libfprint2.py - Refined diagnostic: longer settle after reset,
proper wake sequence, and compare kernel read() vs XFER paths.

Key finding from v1: kernel read() returns 0xFF, XFER returns 0x00.
Both are wrong. Need proper settle + wake to get sensor responding first.
"""
import fcntl, os, struct, sys, time, ctypes

DEV = "/dev/focal_moh_spi"
IOC_RESET = 0x8086
IOC_XFER  = 0x80A0
N_XFER = 16; BUF_SZ = 4096; XFER_SIZE = 16 + N_XFER * 8 + 2 * BUF_SZ
NOTX = 0x01; NORX = 0x02
libc = ctypes.CDLL("libc.so.6", use_errno=True)

def xfer(fd, steps, mode=0xFFFFFFFF, hz=0, pre=0):
    buf = bytearray(XFER_SIZE)
    struct.pack_into("<IIII", buf, 0, len(steps), mode, hz, pre)
    off, lens = 0, []
    for i, (d, cs, dl) in enumerate(steps):
        if isinstance(d, int): n, fl = d, NOTX
        else: n, fl = len(d), 0; buf[16+N_XFER*8+off:16+N_XFER*8+off+n] = d
        struct.pack_into("<IHBB", buf, 16+i*8, n, dl, cs, fl)
        lens.append((off, n)); off += n
    fcntl.ioctl(fd, IOC_XFER, buf, True)
    base = 16 + N_XFER * 8 + BUF_SZ
    return [bytes(buf[base+o:base+o+n]) for o, n in lens]

def kernel_read_wtr(fd, tx_data, rx_len):
    """Use kernel read() path = spi_write_then_read"""
    hdr = struct.pack("<BHH", 0xA5, len(tx_data), rx_len)
    payload = hdr + bytes(tx_data)
    count = len(payload)
    buf_size = max(count, rx_len)
    c_buf = ctypes.create_string_buffer(payload, buf_size)
    ret = libc.read(fd, c_buf, count)
    if ret < 0: return None
    return bytes(c_buf.raw[:rx_len])

def kernel_write(fd, tx_data):
    """Use kernel write() path = spi_write"""
    hdr = struct.pack("<BHH", 0xA5, len(tx_data), 0)
    buf = hdr + bytes(tx_data)
    return os.write(fd, buf)

def tag(label, rx):
    h = rx.hex() if rx else "FAILED"
    print(f"  {label:40s} -> {h}")
    return rx

fd = os.open(DEV, os.O_RDWR)

print("=" * 72)
print("PHASE 0: Confirm sensor alive with known-good winid.py sequence")
print("=" * 72)
# Don't reset, just try the wake+read pattern
print("0a. Wake [FF 00 00 00], 5ms settle, then reg 0x91 full-duplex")
xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)], 0, 1000000)
time.sleep(0.005)
fr91 = bytes([0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00]) + bytes(0x20)
rx91 = xfer(fd, [(fr91, 0, 0)], 0, 1000000)[0]
data91 = rx91[7:]
id_ok = len(data91) > 0x14 and data91[0x13] == 0x93 and data91[0x14] == 0x68
print(f"  reg 0x91 data[0x13:0x15] = {data91[0x13]:02x} {data91[0x14]:02x}" if len(data91) > 0x14 else "  short")
print(f"  {'✓ FT9368 confirmed' if id_ok else '✗ NOT FT9368 — try after reset'}")

if not id_ok:
    print()
    print("0b. Reset, wait 100ms, wake, 5ms, retry")
    fcntl.ioctl(fd, IOC_RESET, 1)
    time.sleep(0.1)
    xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)], 0, 1000000)
    time.sleep(0.005)
    rx91 = xfer(fd, [(fr91, 0, 0)], 0, 1000000)[0]
    data91 = rx91[7:]
    id_ok = len(data91) > 0x14 and data91[0x13] == 0x93 and data91[0x14] == 0x68
    print(f"  reg 0x91 data[0x13:0x15] = {data91[0x13]:02x} {data91[0x14]:02x}" if len(data91) > 0x14 else "  short")
    print(f"  {'✓ FT9368 confirmed' if id_ok else '✗ STILL NOT FT9368'}")

if not id_ok:
    print()
    print("0c. Reset, wait 500ms, wake, 5ms, retry")
    fcntl.ioctl(fd, IOC_RESET, 1)
    time.sleep(0.5)
    xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)], 0, 1000000)
    time.sleep(0.005)
    rx91 = xfer(fd, [(fr91, 0, 0)], 0, 1000000)[0]
    data91 = rx91[7:]
    id_ok = len(data91) > 0x14 and data91[0x13] == 0x93 and data91[0x14] == 0x68
    print(f"  reg 0x91 data[0x13:0x15] = {data91[0x13]:02x} {data91[0x14]:02x}" if len(data91) > 0x14 else "  short")
    print(f"  {'✓ FT9368 confirmed' if id_ok else '✗ STILL NOT FT9368'}")

if not id_ok:
    print("\n!!! Sensor not responding to reg 0x91 via XFER. Cannot proceed with diagnosis.")
    print("!!! This may indicate the sensor is in an unknown state.")
    print("!!! Try: sudo rmmod focal_spi && sudo insmod focal_spi.ko && re-run")
    # Still try the kernel path for comparison
    
print()
print("=" * 72)
print("PHASE 1: Compare SPI transport paths (sensor may or may not respond)")
print("=" * 72)

# Test the libfprint register protocol vs XFER with various read methods
# After wake (no reset — sensor should still be alive)
print()
print("--- 1A: 8-bit read of several registers, comparing methods ---")
for reg in [0xC6, 0x00, 0x01, 0x02, 0x90, 0x91]:
    tx = bytes([0x08, 0xF7, reg, 0x00])
    # Method 1: kernel spi_write_then_read
    r1 = kernel_read_wtr(fd, tx, 1)
    # Method 2: XFER full-duplex
    r2 = xfer(fd, [(tx + b'\x00', 0, 0)], 0, 1000000)[0]
    # Method 3: XFER write then read (CS held, no cs_change)
    r3 = xfer(fd, [(tx, 0, 0), (1, 0, 0)], 0, 1000000)
    # Method 4: XFER cs_change split 
    r4 = xfer(fd, [(tx, 1, 0), (1, 0, 0)], 0, 1000000)
    
    v1 = f"{r1[0]:02x}" if r1 else "!!"
    v2 = f"{r2[4]:02x}"  # 5th byte in full-duplex
    v3 = f"{r3[1][0]:02x}"  # 2nd transfer data
    v4 = f"{r4[1][0]:02x}"  # 2nd transfer data (after CS toggle)
    print(f"  reg 0x{reg:02x}: kernel_wtr={v1}  xfer_fd={v2}  xfer_held={v3}  xfer_split={v4}")

print()
print("--- 1B: libfprint 16-bit chip ID read (reg 0x1A8B) ---")
tx_id = bytes([0x04, 0xFB, 0x8B, 0x9A, 0x00, 0x00])
# Kernel path
r1 = kernel_read_wtr(fd, tx_id, 4)
# XFER full-duplex  
r2 = xfer(fd, [(tx_id + b'\x00\x00\x00\x00', 0, 0)], 0, 1000000)[0]
# XFER CS held
r3 = xfer(fd, [(tx_id, 0, 0), (4, 0, 0)], 0, 1000000)
# XFER CS split
r4 = xfer(fd, [(tx_id, 1, 0), (4, 0, 0)], 0, 1000000)
print(f"  kernel_wtr:  {r1.hex() if r1 else 'FAILED'}")
print(f"  xfer_fd:     {r2.hex()}")
print(f"  xfer_held:   frame={r3[0].hex()} data={r3[1].hex()}")
print(f"  xfer_split:  frame={r4[0].hex()} data={r4[1].hex()}")

print()
print("--- 1C: Windows-style app-ID read (reg 0x91, 0x20 bytes) ---")
fr91 = bytes([0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00])
# Kernel path
r1 = kernel_read_wtr(fd, fr91, 0x20)
# XFER full-duplex
r2 = xfer(fd, [(fr91 + bytes(0x20), 0, 0)], 0, 1000000)[0]
# XFER CS held
r3 = xfer(fd, [(fr91, 0, 0), (0x20, 0, 0)], 0, 1000000)
print(f"  kernel_wtr: {r1.hex() if r1 else 'FAILED'}")
print(f"  xfer_fd:    ...{r2[7:].hex()}")
print(f"  xfer_held:  data={r3[1].hex()}")

# Check if any path got 93 68
for label, rx, off in [("kernel_wtr", r1, 0x13), ("xfer_fd", r2[7:], 0x13), ("xfer_held", r3[1], 0x13)]:
    if rx and len(rx) > off+1:
        if rx[off] == 0x93 and rx[off+1] == 0x68:
            print(f"  ✓ {label} got 93 68 at offset 0x{off:02x}")

print()
print("=" * 72)
print("PHASE 2: Test if sensor needs wake before libfprint-style reads")
print("=" * 72)
print()
print("2a. Wake [FF 00 00 00], 5ms, then libfprint-style reads")
xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)], 0, 1000000)
time.sleep(0.005)

for reg in [0xC6, 0x00, 0x01, 0x02]:
    tx = bytes([0x08, 0xF7, reg, 0x00])
    r1 = kernel_read_wtr(fd, tx, 1)
    r2 = xfer(fd, [(tx + b'\x00', 0, 0)], 0, 1000000)[0]
    r3 = xfer(fd, [(tx, 0, 0), (1, 0, 0)], 0, 1000000)
    v1 = f"{r1[0]:02x}" if r1 else "!!"
    v2 = f"{r2[4]:02x}"
    v3 = f"{r3[1][0]:02x}"
    print(f"  reg 0x{reg:02x}: kernel_wtr={v1}  xfer_fd={v2}  xfer_held={v3}")

print()
print("2b. Wake, then libfprint chip ID read (0x1A8B)")
xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)], 0, 1000000)
time.sleep(0.005)
tx_id = bytes([0x04, 0xFB, 0x8B, 0x9A, 0x00, 0x00])
r1 = kernel_read_wtr(fd, tx_id, 4)
r2 = xfer(fd, [(tx_id + b'\x00\x00\x00\x00', 0, 0)], 0, 1000000)[0]
r3 = xfer(fd, [(tx_id, 0, 0), (4, 0, 0)], 0, 1000000)
print(f"  kernel_wtr:  {r1.hex() if r1 else 'FAILED'}")
print(f"  xfer_fd:     {r2.hex()}")
print(f"  xfer_held:   {r3[0].hex()} | {r3[1].hex()}")

print()
print("2c. Wake, then Windows app-ID (0x91) via ALL methods")
xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)], 0, 1000000)
time.sleep(0.005)
fr91 = bytes([0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00])
r1 = kernel_read_wtr(fd, fr91, 0x20)
print(f"  kernel_wtr:       {r1.hex() if r1 else 'FAILED'}")
# Check 93 68 at various offsets in r1
if r1:
    for i in range(len(r1)-1):
        if r1[i] == 0x93 and r1[i+1] == 0x68:
            print(f"  ✓ Found 93 68 at offset {i} in kernel_wtr!")

xfer(fd, [(b"\xff\x00\x00\x00", 0, 0)], 0, 1000000)
time.sleep(0.005)
r2 = xfer(fd, [(fr91 + bytes(0x20), 0, 0)], 0, 1000000)[0]
print(f"  xfer_fd:          ...{r2[7:].hex()}")
if len(r2) > 7:
    d = r2[7:]
    for i in range(len(d)-1):
        if d[i] == 0x93 and d[i+1] == 0x68:
            print(f"  ✓ Found 93 68 at offset {i} in xfer_fd data!")

os.close(fd)
print()
print("DONE")
