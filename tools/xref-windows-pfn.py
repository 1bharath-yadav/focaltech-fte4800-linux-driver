from pathlib import Path
import struct

f=Path("/home/archer/projects/zerobook-focaltech-driver/reference/failed-fte4800-project/ftWbioUmdfDriverV2.dll")
b=f.read_bytes()
e=struct.unpack_from("<16sHHIQQQIHHHHHH", b, 0)
_,_,_,_,_,shoff,_,_,_,_,_,shentsize,shnum,shstrndx=e
secs=[]
for i in range(shnum):
    sh=struct.unpack_from("<IIQQQQIIQQ",b,shoff+i*shentsize)
    secs.append(sh)
shstr=secs[shstrndx]
tab=b[shstr[4]:shstr[4]+shstr[5]]
def nm(x):
    j=tab.find(b"\0",x)
    return tab[x:j].decode(errors="replace")
for sh in secs:
    name=nm(sh[0])
    if name in (".text",".rdata"):
        print(name,hex(sh[3]),hex(sh[4]),hex(sh[5]))

text=next(s for s in secs if nm(s[0])==".text")
rdata=next(s for s in secs if nm(s[0])==".rdata")
to,ts,tva=text[4],text[5],text[3]
ro,rs,rva=rdata[4],rdata[5],rdata[3]
names=["ft_feature_devinit_9368POADetectFingerPress",
       "ft_feature_devinit_9368ReadChipID",
       "Sensor type: %d(1=FT9338W, 2=FT9348W, 3=FT9361W, 4=FT9368W, 5=FT9371W, 6=FT9536W, 7=FT9362W)"]
for name in names:
    q=b.find(name.encode(),ro,ro+rs)
    va=rva+q-ro
    refs=[]
    for i in range(to,to+ts-7):
        if b[i:i+3] in (b"\x48\x8d\x05",b"\x48\x8d\x0d",b"\x48\x8d\x15",b"\x48\x8d\x1d",
                        b"\x48\x8d\x25",b"\x48\x8d\x2d",b"\x4c\x8d\x05",b"\x4c\x8d\x0d",
                        b"\x4c\x8d\x15",b"\x4c\x8d\x1d",b"\x4c\x8d\x25",b"\x4c\x8d\x2d"):
            disp=struct.unpack_from("<i",b,i+3)[0]
            sva=tva+i-to
            dest=sva+7+disp
            if dest==va: refs.append(sva)
    print(name, "va",hex(va),"refs",[hex(x) for x in refs])
