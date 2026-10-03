#!/usr/bin/env python3
import ctypes,fcntl,os,struct,time
DEV='/dev/focal_moh_spi'; RAW=0x80A0; RESET=0x8086; SZ=16+16*8+16384*2
NOTX=1; NORX=2; libc=ctypes.CDLL(None,use_errno=True)

def xfer(fd,steps,tx):
 b=bytearray(SZ); struct.pack_into('<IIII',b,0,len(steps),0xffffffff,1_000_000,0); o=0
 for i,(n,d,c,f) in enumerate(steps):
  struct.pack_into('<IHBB',b,16+i*8,n,d,c,f); b[16+16*8+o:16+16*8+o+n]=tx[o:o+n]; o+=n
 rc=libc.ioctl(fd,ctypes.c_ulong(RAW),ctypes.byref((ctypes.c_ubyte*SZ).from_buffer(b)))
 if rc<0: raise OSError(ctypes.get_errno(),os.strerror(ctypes.get_errno()))
 return bytes(b[16+16*8+16384:16+16*8+16384+o])
def wr(fd,p): xfer(fd,[(len(p),0,0,NORX)],p)
def rdsp(fd,reg,n):
 wr(fd,b'\xff\x00\x00\x00'); time.sleep(.001)
 hdr=bytes([reg,0x80,n>>8,n&255,0,0,0])
 r=xfer(fd,[(7,0,0,NORX),(n,0,1,NOTX)],hdr+b'\0'*n)
 return r[7:7+n],r
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
try:
 fcntl.ioctl(fd,RESET,0); time.sleep(.02)
 for p,sl in [(b'\xff\0\0\0',.02),(b'\x70',.1),(b'\xc0\x3f\0',.05),(b'\xff\0\0\0',.02)]: wr(fd,p); time.sleep(sl)
 print('status',rdsp(fd,0x80,1)[0].hex())
 wr(fd,b'\x70\x55\xaa'); time.sleep(.01)
 for reg,n in [(0x90,2),(0x80,1),(0x91,2)]:
  print(hex(reg),rdsp(fd,reg,n)[0].hex())
finally: os.close(fd)
