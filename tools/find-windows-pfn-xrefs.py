import pefile, struct, subprocess, re
from pathlib import Path

f=Path("/home/archer/projects/zerobook-focaltech-driver/reference/failed-fte4800-project/ftWbioUmdfDriverV2.dll")
pe=pefile.PE(str(f))
text=next(s for s in pe.sections if s.Name[:5] == b".text")
rdata=next(s for s in pe.sections if s.Name[:6] == b".rdata")
base=pe.OPTIONAL_HEADER.ImageBase
text_va=base+text.VirtualAddress
text_raw=text.PointerToRawData
text_size=text.Misc_VirtualSize
raw=f.read_bytes()

targets=[
    b"ft_feature_devinit_9368POADetectFingerPress",
    b"ft_feature_devinit_9368ReadChipID",
    b"[Driver] I %s[%d]: FT9368 POA detect finger press",
    b"[Driver] I %s[%d]: 9368 Chipid = 0x%x",
]
for target in targets:
    q=raw.find(target)
    if q<0:
        print(target, "NOT_FOUND")
        continue
    rva=pe.get_rva_from_offset(q)
    va=base+rva
    print("TARGET",target.decode(errors="replace"),"VA",hex(va),"RVA",hex(rva))
    hits=[]
    end=text_raw+text_size
    for off in range(text_raw,end-7):
        op=raw[off:off+3]
        if op in (
            b"\x48\x8d\x05",b"\x48\x8d\x0d",b"\x48\x8d\x15",
            b"\x48\x8d\x1d",b"\x48\x8d\x25",b"\x48\x8d\x2d",
            b"\x4c\x8d\x05",b"\x4c\x8d\x0d",b"\x4c\x8d\x15",
            b"\x4c\x8d\x1d",b"\x4c\x8d\x25",b"\x4c\x8d\x2d",
            b"\x48\x8b\x05",b"\x48\x8b\x0d",b"\x48\x8b\x15",
            b"\x48\x8b\x1d",b"\x48\x8b\x25",b"\x48\x8b\x2d",
        ):
            disp=struct.unpack_from("<i",raw,off+3)[0]
            src_va=base+pe.get_rva_from_offset(off)
            dest=src_va+7+disp
            if dest==va:
                hits.append(src_va)
    print("XREFS",[hex(x) for x in hits[:100]],"count",len(hits))
