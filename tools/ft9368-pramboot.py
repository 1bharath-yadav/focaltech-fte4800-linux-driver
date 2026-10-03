#!/usr/bin/env python3
import fcntl, hashlib, os, struct, sys, time
from pathlib import Path
ROOT=Path('/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver')
FW=ROOT.parent.parent/'extracted-windows-fw'/'FT9368_PRAMBOOT.bin'
DEV='/dev/focal_moh_spi'; IOC_RAW_XFER=0x80A0; IOC_RESET=0x8086
N=16; BUF=16384; SIZE=16+N*8+2*BUF; NORX=2

def one_xfer(fd,tx,rx_len=0,delay_us=0,cs_change=0):
    b=bytearray(SIZE); struct.pack_into('<IIII',b,0,1,0xffffffff,1000000,0)
    d=bytes(tx); ln=max(len(d),rx_len)
    b[16+N*8:16+N*8+len(d)]=d
    struct.pack_into('<IHBB',b,16,ln,delay_us,cs_change,NORX if rx_len==0 else 0)
    fcntl.ioctl(fd,IOC_RAW_XFER,b,True)
    return bytes(b[16+N*8+BUF:16+N*8+BUF+rx_len])

def wr(fd,data): return one_xfer(fd,data)
def rdspi(fd,reg,n):
    tx=bytes([reg&255,0x80,(n>>8)&255,n&255,0,0,0])+bytes(n)
    return one_xfer(fd,tx,n)[7:7+n]
def sfr_write(fd,addr,val):
    # Windows fcn.18001b4e4 exact layout: 70 07 F8 addr_hi addr_lo 00 00 val_hi val_lo 00 00
    wr(fd,bytes([0x70,0x07,0xF8,(addr>>8)&255,addr&255,0,0,(val>>8)&255,val&255,0,0]))
def cmd70(fd,cmd): wr(fd,bytes([0x70,cmd&255,(~cmd)&255]))
def pram_write(fd,addr,data):
    count=len(data)//4-1
    wr(fd,bytes([0x70,0x05,0xFA,(addr>>8)&255,addr&255,(count>>8)&255,count&255])+data)
def pram_read(fd,addr,nbytes):
    count=nbytes//4-1
    hdr=bytes([0x70,0x04,0xFB,(addr>>8)&255,addr&255,(count>>8)&255,count&255])
    one_xfer(fd,hdr,0); time.sleep(0.001)
    return one_xfer(fd,bytes([0x71])+bytes(nbytes),nbytes+1)[1:]
def main():
    data=FW.read_bytes(); sha=hashlib.sha256(data).hexdigest()
    print(f'PRAMBOOT size={len(data)} sha256={sha}')
    if len(data)!=6096 or sha!='c93a807eaaa34d9e79fbab77b86e910a419fd633ea98b628b72c64b285ffd191': raise SystemExit('refuse: PRAMBOOT integrity gate failed')
    if '--run' not in sys.argv: print('DRY RUN; pass --run to execute volatile PRAMBOOT load'); return
    fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
    try:
        fcntl.ioctl(fd,IOC_RESET,0); time.sleep(.020)
        cmd70(fd,0x55); sfr_write(fd,0x0004,0xAA55); sfr_write(fd,0x0048,0x0110)
        print('entry sequence sent')
        for off in range(0,len(data),128):
            chunk=data[off:off+128]; pram_write(fd,0x2000+off//4,chunk); print(f'write {off+len(chunk):4d}/6096 addr=0x{0x2000+off//4:04x}')
        for off in range(0,len(data),256):
            chunk=data[off:off+256]; got=pram_read(fd,0x2000+off//4,len(chunk))
            if got!=chunk:
                print(f'VERIFY_FAIL offset={off} addr=0x{0x2000+off//4:04x}'); print('expected',chunk[:32].hex(' ')); print('got     ',got[:32].hex(' ')); raise SystemExit(2)
            print(f'verify {off+len(chunk):4d}/6096 addr=0x{0x2000+off//4:04x}')
        sfr_write(fd,0x0007,0x5A5A); cmd70(fd,0x0A); time.sleep(.010)
        status=rdspi(fd,0x91,2); print('postload 91/2 =',status.hex(' '))
        if status!=bytes.fromhex('55 aa'): raise SystemExit('postload guard failed')
        info=rdspi(fd,0x91,32); print('91/32 =',info.hex(' ')); print('chip @19 =',info[19:21].hex(' '))
    finally: os.close(fd)
if __name__=='__main__': main()
