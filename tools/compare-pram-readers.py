#!/usr/bin/env python3
import fcntl, hashlib, os, struct, time
from pathlib import Path
ROOT=Path('/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver'); FW=ROOT.parent.parent/'extracted-windows-fw'/'FT9368_PRAMBOOT.bin'; DEV='/dev/focal_moh_spi'; IOC=0x80A0; RESET=0x8086; N=16; BUF=16384; SIZE=16+N*8+2*BUF

def x(fd,tx,rx=0):
 b=bytearray(SIZE); struct.pack_into('<IIII',b,0,1,0xffffffff,1000000,0); d=bytes(tx); n=max(len(d),rx); b[16+N*8:16+N*8+len(d)]=d; struct.pack_into('<IHBB',b,16,n,0,0,2 if not rx else 0); fcntl.ioctl(fd,IOC,b,True); return bytes(b[16+N*8+BUF:16+N*8+BUF+rx])
def wr(fd,d): x(fd,d)
def sfr(fd,a,v): wr(fd,bytes([0x70,7,0xF8,a>>8,a&255,v>>8,v&255,0,0,0,0]))
def cmd(fd,c): wr(fd,bytes([0x70,c,(-c)&255]))
def wram(fd,a,d):
 n=len(d)//4-1; wr(fd,bytes([0x70,5,0xFA,a>>8,a&255,n>>8,n&255])+d)
def reader_b(fd,a,n):
 nwords=n//4; count=nwords-1; hdr=bytes([0x70,4,0xFB,a>>8,a&255,count>>8,count&255]); x(fd,hdr); time.sleep(.001); return x(fd,bytes([0x71])+bytes(n),n+1)[1:]
def reader_a(fd,a,count):
 # vendor backend A: address/0x80 header followed by clocks in one full-duplex transfer
 hdr=bytes([a>>8,0x80,a&255,count>>8,count&255,0,0]); return x(fd,hdr+bytes(count),len(hdr)+count)[7:7+count]
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
d=FW.read_bytes()
try:
 fcntl.ioctl(fd,RESET,0); time.sleep(.02); cmd(fd,0x55); sfr(fd,4,0xaa55); sfr(fd,0x48,0x110)
 for o in range(0,len(d),128): wram(fd,0x2000+o//4,d[o:o+128])
 print('backend-B=',reader_b(fd,0x2000,256).hex(' '))
 print('backend-A=',reader_a(fd,0x2000,256).hex(' '))
finally: os.close(fd)
