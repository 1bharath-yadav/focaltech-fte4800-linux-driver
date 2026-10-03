from pathlib import Path
import struct
b=Path("/usr/lib/libfprint-2.so.2.0.0").read_bytes()
TEXT_OFF=0x129e0
TEXT_SIZE=0x14dfe2
TEXT_VA=0x129e0
RO_OFF=0x161000
RO_SIZE=0x60fe0
RO_VA=0x161000

targets=[
 b"[%4d]:fw9362_dev_init ret: %d",
 b"fw9368_NoneSlideEnrollReadImage",
 b"focal_fp_sensor_read_fw9368_image",
 b"FT9368",
]
for target in targets:
    pos=b.find(target,RO_OFF,RO_OFF+RO_SIZE)
    print("target",target.decode(errors="replace"),"vaddr",
          hex(RO_VA+pos-RO_OFF) if pos>=0 else "NOT_FOUND")
    if pos<0:
        continue
    va=RO_VA+pos-RO_OFF
    refs=[]
    for i in range(TEXT_OFF,TEXT_OFF+TEXT_SIZE-7):
        op=b[i:i+3]
        if op not in (
            b"\x48\x8d\x05",b"\x48\x8d\x0d",b"\x48\x8d\x15",
            b"\x48\x8d\x1d",b"\x48\x8d\x35",b"\x48\x8d\x3d",
            b"\x4c\x8d\x05",b"\x4c\x8d\x0d",b"\x4c\x8d\x15",
            b"\x4c\x8d\x1d",b"\x4c\x8d\x25",b"\x4c\x8d\x2d"):
            continue
        disp=struct.unpack_from("<i",b,i+3)[0]
        src=TEXT_VA+(i-TEXT_OFF)
        if src+7+disp==va:
            refs.append(src)
    print("rip_refs", [hex(x) for x in refs], "count",len(refs))

for value in (0x9368,0x9362,0xA506,0x0EEF,0xCECE):
    found=[]
    for width in (2,4):
        pat=value.to_bytes(width,"little")
        start=TEXT_OFF
        while True:
            q=b.find(pat,start,TEXT_OFF+TEXT_SIZE)
            if q<0:
                break
            found.append(TEXT_VA+q-TEXT_OFF)
            start=q+1
            if len(found)>=40:
                break
    print("value",hex(value),"hits", [hex(x) for x in found[:40]], "count",len(found))
