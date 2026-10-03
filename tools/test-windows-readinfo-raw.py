#!/usr/bin/env python3
import ctypes, os, struct, sys
DEV="/dev/focal_moh_spi"
A5=0xA5
tx=bytes.fromhex("91 80 00 20 00 00 00")
rx_len=32
RESET=0x8086
libc=ctypes.CDLL(None,use_errno=True)
libc.ioctl.argtypes=[ctypes.c_int,ctypes.c_ulong,ctypes.c_ulong]
libc.ioctl.restype=ctypes.c_int
libc.read.argtypes=[ctypes.c_int,ctypes.c_void_p,ctypes.c_size_t]
libc.read.restype=ctypes.c_ssize_t
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
try:
    if libc.ioctl(fd,RESET,0)<0:
        e=ctypes.get_errno(); raise OSError(e,os.strerror(e))
    req=bytearray(max(5+len(tx),rx_len))
    struct.pack_into("<BHH",req,0,A5,len(tx),rx_len)
    req[5:5+len(tx)]=tx
    b=(ctypes.c_ubyte*len(req)).from_buffer_copy(req)
    n=libc.read(fd,ctypes.byref(b),len(req))
    if n<0:
        e=ctypes.get_errno(); raise OSError(e,os.strerror(e))
    print("tx:",tx.hex(" "))
    print("rx:",bytes(b[:n]).hex(" "))
    print("first2:",bytes(b[5:7]).hex(" "))
finally:
    os.close(fd)
