#!/usr/bin/env python3
import ctypes, fcntl, hashlib, os, struct, time
from pathlib import Path
ROOT=Path('/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver')
FW=ROOT.parent.parent/'extracted-windows-fw'/'FT9368_PRAMBOOT.bin'
DEV='/dev/focal_moh_spi'; RAW=0x80A0; RESET=0x8086
N=16; BUF=16384; SIZE=16+N*8+2*BUF; NORX=2
libc=ctypes.CDLL(None,use_errno=True)

def raw(fd,steps,tx=b'',mode=0xffffffff,speed=1_000_000):
    b=bytearray(SIZE); struct.pack_into('<IIII',b,0,len(steps),mode,speed,0)
    off=0
    for i,(ln,delay,cs,flags) in enumerate(steps):
        struct.pack_into('<IHBB',b,16+i*8,ln,delay,cs,flags)
        if tx: b[16+N*8+off:16+N*8+off+min(ln,len(tx)-off)]=tx[off:off+ln]
        off+=ln
    fcntl.ioctl(fd,RAW,b,True)
    out=bytes(b[16+N*8+BUF:16+N*8+BUF+off])
    return out

def wr(fd,p): raw(fd,[(len(p),0,0,NORX)],p)
def cmd(fd,c): wr(fd,bytes([0x70,c,(-c)&255]))
def sfrw(fd,a,v): wr(fd,bytes([0x70,7,0xf8,a>>8,a&255,0,0,v>>8,v&255,0,0]))
def pramw(fd,a,d):
    assert len(d)%4==0
    count=len(d)//4-1
    wr(fd,bytes([0x70,5,0xfa,a>>8,a&255,count>>8,count&255])+d)
def pramr(fd,a,n):
    assert n%4==0
    count=n//4-1
    hdr=bytes([0x70,4,0xfb,a>>8,a&255,count>>8,count&255])
    wr(fd,hdr); time.sleep(.001)
    total=n+4
    got=raw(fd,[(total,0,0,0)],bytes([0x71])+bytes(total-1))
    return got[4:4+n],got
def spi90(fd,reg,n):
    p=bytes([reg,0x80,n>>8,n&255,0,0,0])+bytes(n)
    got=raw(fd,[(len(p),0,0,0)],p)
    return got
def main():
    data=FW.read_bytes(); sha=hashlib.sha256(data).hexdigest()
    print('FW',len(data),sha,flush=True)
    assert len(data)==6096 and sha=='c93a807eaaa34d9e79fbab77b86e910a419fd633ea98b628b72c64b285ffd191'
    fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
    try:
        fcntl.ioctl(fd,RESET,0); time.sleep(.020)
        cmd(fd,0x55); sfrw(fd,4,0xaa55); sfrw(fd,0x48,0x0110); time.sleep(.002)
        for a in (4,0x48):
            got,rawgot=pramr(fd,a,4)
            print('pre-read',hex(a),got.hex(' '),'raw',rawgot.hex(' '),flush=True)
        for off in range(0,len(data),128):
            pramw(fd,0x2000+off//4,data[off:off+128])
        print('PRAM written',flush=True)
        for off in range(0,len(data),256):
            got,rawgot=pramr(fd,0x2000+off//4,256)
            exp=data[off:off+256]
            if got!=exp:
                print('VERIFY_FAIL',off,'raw',rawgot[:24].hex(' '),flush=True)
                print('exp',exp[:32].hex(' ')); print('got',got[:32].hex(' ')); return 2
        print('PRAM VERIFY OK',flush=True)
        sfrw(fd,7,0x5a5a); cmd(fd,0x0a); time.sleep(.010)
        for reg,n in [(0x91,2),(0x91,32),(0x90,2)]:
            print('spi90',hex(reg),n,spi90(fd,reg,n).hex(' '),flush=True)
    finally: os.close(fd)
if __name__=='__main__': main()
