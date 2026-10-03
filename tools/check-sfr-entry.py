#!/usr/bin/env python3
import fcntl, os, struct, time
DEV='/dev/focal_moh_spi'; IOC=0x80A0; RESET=0x8086; N=16; BUF=16384; SIZE=16+N*8+2*BUF

def x(fd,tx,rx=0):
 b=bytearray(SIZE); struct.pack_into('<IIII',b,0,1,0xffffffff,1000000,0); d=bytes(tx); n=max(len(d),rx); b[16+N*8:16+N*8+len(d)]=d; struct.pack_into('<IHBB',b,16,n,0,0,2 if not rx else 0); fcntl.ioctl(fd,IOC,b,True); return bytes(b[16+N*8+BUF:16+N*8+BUF+rx])
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
try:
 fcntl.ioctl(fd,RESET,0); time.sleep(.02)
 for a,v in [(4,0xaa55),(0x48,0x0110)]:
  p=bytes([0x70,7,0xf8,a>>8,a&255,0,0,v>>8,v&255,0,0]); x(fd,p); print('write',hex(a),p.hex(' '));
  time.sleep(.002)
 # Windows SPI0_Read16 exact: 04 fb (addr_hi|80) addr_lo 00 01, then 2 clocks in same full-duplex transaction.
 for a in (4,0x48):
  tx=bytes([4,0xfb,((a>>8)&255)|0x80,a&255,0,1])+bytes(2); raw=x(fd,tx,len(tx)); print('read',hex(a),'raw',raw.hex(' '),'be16',hex((raw[0]<<8)|raw[1]) if len(raw)>=2 else 'short')
finally: os.close(fd)
