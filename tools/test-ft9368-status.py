#!/usr/bin/env python3
import ctypes, os, struct, time
DEV="/dev/focal_moh_spi"
RESET=0x8086
A5=0xA5
TX=bytes.fromhex("04 fb 91 80 00 03")
def xr(fd, tx):
    req=bytearray(max(5+len(tx),6))
    struct.pack_into("<BHH",req,0,A5,len(tx),6)
    req[5:5+len(tx)]=tx
    buf=(ctypes.c_ubyte*len(req)).from_buffer_copy(req)
    n=libc.read(fd,ctypes.byref(buf),len(req))
    if n<0:
        e=ctypes.get_errno(); raise OSError(e,os.strerror(e))
    return bytes(buf[:n])
libc=ctypes.CDLL(None,use_errno=True)
libc.ioctl.argtypes=[ctypes.c_int,ctypes.c_ulong,ctypes.c_ulong]; libc.ioctl.restype=ctypes.c_int
libc.read.argtypes=[ctypes.c_int,ctypes.c_void_p,ctypes.c_size_t]; libc.read.restype=ctypes.c_ssize_t
fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
try:
    poller = __import__("select").poll()
    print("PLACE FINGER ON SENSOR NOW", flush=True)
    while True:
        if libc.ioctl(fd,RESET,0)<0:
            e=ctypes.get_errno(); raise OSError(e,os.strerror(e))
        time.sleep(0.005)
        data=xr(fd,TX)
        print(data.hex(" "), "status_byte_2=",hex(data[2]),flush=True)
        poller.poll(250)
finally:
    os.close(fd)
