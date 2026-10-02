#!/usr/bin/env python3
"""ffx.py - sweep SPI transport variables against FT9368 chip-ID read (0x90 -> 56 A2)
via the FF_IOC_XFER spi_sync() debug ioctl on /dev/focal_moh_spi.  Run as root.
Hypothesis: Windows SPB backend != spi_write_then_read; CS framing/mode/prelude decides.
"""
import fcntl, os, struct, sys, time, itertools

DEV = "/dev/focal_moh_spi"
IOC_RESET, IOC_XFER = 0x8086, 0x80A0
N, BUF = 16, 4096
SIZE = 16 + N * 8 + 2 * BUF
NOTX, NORX = 1, 2
WANT = bytes([0x56, 0xA2])
F = bytes([0x90, 0x80, 0x00, 0x02, 0x00, 0x00, 0x00])   # Windows 7-byte frame
R = bytes([0x08, 0xF7, 0x90, 0x00, 0x00])               # Write/Read8-style frame

def xfer(fd, steps, mode=0xFFFFFFFF, hz=0, pre=0):
    """steps: list of (tx|int_rx_len, cs_change, delay_us). tx bytes => full duplex."""
    buf = bytearray(SIZE)
    struct.pack_into("<IIII", buf, 0, len(steps), mode, hz, pre)
    off, lens = 0, []
    for i, (d, cs, dl) in enumerate(steps):
        if isinstance(d, int):
            n, fl = d, NOTX
        else:
            n, fl = len(d), 0
            buf[16 + N * 8 + off:16 + N * 8 + off + n] = d
        struct.pack_into("<IHBB", buf, 16 + i * 8, n, dl, cs, fl)
        lens.append((off, n)); off += n
    fcntl.ioctl(fd, IOC_XFER, buf, True)
    base = 16 + N * 8 + BUF
    return [bytes(buf[base + o:base + o + n]) for o, n in lens]

def prelude(fd, kind, mode, hz):
    if kind >= 2:                      # dummy wake byte, then 1 ms
        xfer(fd, [(b"\x00", 0, 0)], mode, hz); time.sleep(0.001)
    if kind >= 1:                      # SPI0_CMD_Set(0x55), then 10 ms
        xfer(fd, [(b"\x55\x00\x00\x00", 0, 0)], mode, hz); time.sleep(0.010)

# each experiment = list of messages; each message = list of steps
EXPS = {
 "E1 wtr cs-held   ": [[(F, 0, 0), (2, 0, 0)]],
 "E2 split cs_chg  ": [[(F, 1, 0), (2, 0, 0)]],
 "E3 split+200us   ": [[(F, 1, 200), (2, 0, 0)]],
 "E4 full-duplex 9 ": [[(F + b"\x00\x00", 0, 0)]],
 "E5 2 messages    ": [[(F, 0, 0)], [(2, 0, 0)]],
 "E6 cs-hold+read  ": [[(F, 1, 0)], [(2, 0, 0)]],
 "E7 r8 frame fd   ": [[(R + b"\x00\x00", 0, 0)]],
 "E8 r8 wtr        ": [[(R, 0, 0), (2, 0, 0)]],
}

def run(fd, log):
    hits = []
    for pre_k, mode, hz in itertools.product((0, 1, 2), (0, 1, 2, 3), (500000, 1000000, 4000000)):
        for name, msgs in EXPS.items():
            prelude(fd, pre_k, mode, hz)
            outs = []
            for m in msgs:
                outs += xfer(fd, m, mode, hz)
            flat = b"".join(outs)
            hit = WANT in flat
            line = f"pre={pre_k} mode={mode} hz={hz:>7} {name} rx=" + " | ".join(o.hex() for o in outs) + ("  <== 56A2 !!" if hit else "")
            log.write(line + "\n")
            if hit:
                hits.append(line); print(line)
    return hits

if __name__ == "__main__":
    fd = os.open(DEV, os.O_RDWR)
    if "--reset" in sys.argv:
        print("issuing reset ioctl 0x8086 (patched driver, reviewed)"); sys.stdout.flush()
        fcntl.ioctl(fd, IOC_RESET, 0); time.sleep(0.1)
    with open("sweep-out.txt", "w") as log:
        hits = run(fd, log)
    print(f"done. hits={len(hits)}; full log: sweep-out.txt")
    # summary of distinct rx values so we can see if anything varies at all
    vals = {}
    for l in open("sweep-out.txt"):
        v = l.split("rx=")[1].strip().split("  <==")[0]
        vals[v] = vals.get(v, 0) + 1
    for v, c in sorted(vals.items(), key=lambda kv: -kv[1])[:15]:
        print(f"{c:4d}x  {v}")
