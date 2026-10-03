from pathlib import Path
import struct

B=Path("/usr/lib/libfprint-2.so.2.0.0").read_bytes()
TO=0x129e0; TS=0x14dfe2; TVA=0x129e0
RO=0x161000; RS=0x60fe0; RVA=0x161000

targets = {
    "FTE3600": 0x1653f5,
    "FTE4800": 0x1653fd,
    "FTE6900": 0x165405,
    "fw9368_none": 0x1a4800,
    "fw9368_image": 0x1a4820,
    "fw9362_init": 0x16552d,
}

for name, va in targets.items():
    refs=[]
    for i in range(TO, TO+TS-7):
        op=B[i:i+3]
        if op in (
            b"\x48\x8d\x05", b"\x48\x8d\x0d", b"\x48\x8d\x15",
            b"\x48\x8d\x1d", b"\x48\x8d\x25", b"\x48\x8d\x2d",
            b"\x4c\x8d\x05", b"\x4c\x8d\x0d", b"\x4c\x8d\x15",
            b"\x4c\x8d\x1d", b"\x4c\x8d\x25", b"\x4c\x8d\x2d",
            b"\x48\x8b\x05", b"\x48\x8b\x0d", b"\x48\x8b\x15",
            b"\x48\x8b\x1d", b"\x48\x8b\x25", b"\x48\x8b\x2d"):
            disp=struct.unpack_from("<i",B,i+3)[0]
            src=TVA+(i-TO)
            dest=src+7+disp
            if dest==va:
                refs.append(src)
    print(name, hex(va), "refs", [hex(x) for x in refs])

# direct immediate string pointer patterns via mov/lea not covered above
