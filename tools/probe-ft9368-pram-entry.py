#!/usr/bin/env python3
import ctypes, fcntl, os, struct, time
DEV='/dev/focal_moh_spi'
RAW=0x80A0
RESET=0x8086
MAXN=16
BUF=16384
SZ=16+MAXN*8+2*BUF
NOTX=1
NORX=2
libc=ctypes.CDLL(None,use_errno=True)

def xfer(fd, steps, tx=b''):
    b=bytearray(SZ)
    struct.pack_into('<IIII',b,0,len(steps),0xffffffff,1_000_000,0)
    off=0
    for i,(ln,delay,cs,flags) in enumerate(steps):
        struct.pack_into('<IHBB',b,16+i*8,ln,delay,cs,flags)
        if not (flags&NOTX):
            b[16+MAXN*8+off:16+MAXN*8+off+ln]=tx[off:off+ln]
        off+=ln
    rc=libc.ioctl(fd,ctypes.c_ulong(RAW),ctypes.byref((ctypes.c_ubyte*SZ).from_buffer(b)))
    if rc<0:
        e=ctypes.get_errno(); raise OSError(e,os.strerror(e))
    rx=bytes(b[16+MAXN*8+BUF:16+MAXN*8+BUF+off])
    return rx

def write_tx(fd,p):
    xfer(fd,[(len(p),0,0,NORX)],p)

def read_special(fd,reg,n):
    # Windows SPI0_Read_SPI(reg,n): WakeDevice; 1 ms delay; CS0; write 7-byte
    # [reg,80,n_hi,n_lo,00,00,00]; read n clocks; CS1.
    write_tx(fd,b'\xff\x00\x00\x00')
    time.sleep(.001)
    hdr=bytes([reg,0x80,n>>8,n&255,0,0,0])
    rx=xfer(fd,[(len(hdr),0,0,NORX),(n,0,1,NOTX)],hdr+b'\0'*n)
    return rx[7:7+n],rx

fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
try:
    fcntl.ioctl(fd,RESET,0)
    time.sleep(.020)

    # Exact Windows CMD_Set(0x55): WakeDevice(); 1 ms; CS0; [70 55 AA]; CS1.
    write_tx(fd,b'\xff\x00\x00\x00')
    time.sleep(.001)
    write_tx(fd,b'\x70\x55\xaa')
    time.sleep(.010)

    got,raw=read_special(fd,0x90,2)
    print('SPI0_Read_SPI(90,2) raw=',raw.hex(' '))
    print('value=',got.hex(' '),'expected=56 a2')
finally:
    os.close(fd)
