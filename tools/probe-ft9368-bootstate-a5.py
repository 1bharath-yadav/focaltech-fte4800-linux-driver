#!/usr/bin/env python3
import ctypes, os, time, fcntl
DEV='/dev/focal_moh_spi'; RESET=0x8086; A5=0xA5
libc=ctypes.CDLL(None,use_errno=True)
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
def call_read(tx,n):
 b=bytes([A5])+len(tx).to_bytes(2,'little')+n.to_bytes(2,'little')+tx
 buf=ctypes.create_string_buffer(b,max(len(b),n))
 got=libc.read(fd,ctypes.byref(buf),len(b))
 if got<0: raise OSError(ctypes.get_errno(),os.strerror(ctypes.get_errno()))
 return bytes(buf.raw[:n])
def call_write(tx):
 b=bytes([A5])+len(tx).to_bytes(2,'little')+b'\0\0'+tx
 buf=ctypes.create_string_buffer(b)
 got=libc.write(fd,ctypes.byref(buf),len(b))
 if got<0: raise OSError(ctypes.get_errno(),os.strerror(ctypes.get_errno()))
def wr(p,sl=0.002): call_write(p); time.sleep(sl)
def rd(reg,n):
 return call_read(bytes([reg,0x80,n>>8,n&255,0,0,0]),n)
try:
 fcntl.ioctl(fd,RESET,0); time.sleep(.02)
 wr(bytes.fromhex('ff000000'),.02)
 wr(bytes.fromhex('70'),.10)
 wr(bytes.fromhex('c03f00'),.05)
 wr(bytes.fromhex('ff000000'),.02)
 print('status',call_read(bytes.fromhex('08f7800000'),1).hex())
 wr(bytes.fromhex('ff000000'),.001)
 wr(bytes.fromhex('70 55 aa'),.01)
 print('90',rd(0x90,2).hex())
 print('80',rd(0x80,1).hex())
 print('91',rd(0x91,2).hex())
finally: os.close(fd)
