#!/usr/bin/env python3
import fcntl,os,struct,time
DEV='/dev/focal_moh_spi'; RESET=0x8086
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
def w(tx):
    b=struct.pack('<BHH',0xA5,len(tx),0)+tx; return os.write(fd,b)
def r(tx,n):
    size=max(5+len(tx),n); b=bytearray(size); struct.pack_into('<BHH',b,0,0xA5,len(tx),n); b[5:5+len(tx)]=tx; q=os.pread(fd,size,0) if False else None
    return os.read(fd,size)
try:
    fcntl.ioctl(fd,RESET,0); time.sleep(.02)
    for a,v in [(4,0xaa55),(0x48,0x0110)]:
        p=bytes([0x70,7,0xf8,a>>8,a&255,0,0,v>>8,v&255,0,0]); print('write',p.hex(' ')); w(p); time.sleep(.002)
    for a in (4,0x48):
        p=bytes([4,0xfb,((a>>8)&255)|0x80,a&255,0,1]); raw=r(p,2); print('read',hex(a),'rx',raw[:2].hex(' '),'all',raw.hex(' '))
finally: os.close(fd)
