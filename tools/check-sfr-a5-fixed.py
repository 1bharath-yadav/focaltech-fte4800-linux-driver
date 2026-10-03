#!/usr/bin/env python3
import ctypes, fcntl, os, struct, time
DEV='/dev/focal_moh_spi'; RESET=0x8086
libc=ctypes.CDLL(None, use_errno=True)
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)

def xwrite(tx):
    b=struct.pack('<BHH',0xA5,len(tx),0)+tx
    n=os.write(fd,b)
    assert n==len(b), (n,len(b))

def xread(tx,n):
    size=max(5+len(tx),n)
    b=bytearray(size)
    struct.pack_into('<BHH',b,0,0xA5,len(tx),n)
    b[5:5+len(tx)]=tx
    buf=(ctypes.c_ubyte*size).from_buffer(b)
    got=libc.read(fd,ctypes.byref(buf),size)
    if got < 0:
        e=ctypes.get_errno(); raise OSError(e,os.strerror(e))
    return bytes(b[:got])

try:
    fcntl.ioctl(fd,RESET,0); time.sleep(.020)
    for a,v in [(4,0xaa55),(0x48,0x0110)]:
        p=bytes([0x70,0x07,0xf8,a>>8,a&255,0,0,v>>8,v&255,0,0])
        print('write',p.hex(' ')); xwrite(p); time.sleep(.002)
    for a in (4,0x48):
        p=bytes([0x04,0xfb,((a>>8)&255)|0x80,a&255,0,1])
        raw=xread(p,2)
        print('read',hex(a),'rx',raw[:2].hex(' '),'all',raw.hex(' '))
finally:
    os.close(fd)
