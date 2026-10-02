#!/usr/bin/env python3
import ctypes, os, time

DEV = "/dev/focal_moh_spi"
IOCTL_RESET = 0x8086
SPI_READ_WRITE = 0xA5
libc = ctypes.CDLL(None, use_errno=True)

def err(op):
    e = ctypes.get_errno()
    raise OSError(e, f"{op}: {os.strerror(e)}")

def ioctl_reset(fd):
    if libc.ioctl(fd, ctypes.c_ulong(IOCTL_RESET), ctypes.c_ulong(0)) < 0:
        err("ioctl reset")

def xfer(fd, tx, rxlen=0):
    raw = bytes((SPI_READ_WRITE,)) + len(tx).to_bytes(2,"little") + rxlen.to_bytes(2,"little") + tx
    buf = ctypes.create_string_buffer(raw, len(raw))
    if rxlen:
        n = libc.read(fd, ctypes.byref(buf), len(raw))
    else:
        n = libc.write(fd, ctypes.byref(buf), len(raw))
    if n < 0: err("spi")
    if n != len(raw): raise RuntimeError(f"short transfer {n}/{len(raw)}")
    return bytes(buf.raw[:rxlen]) if rxlen else b""

def wr(fd, label, tx, delay=.005):
    xfer(fd, tx); print(f"WRITE {label:<16} {tx.hex(' ')}"); time.sleep(delay)

def rd8(fd, reg, delay=.005):
    tx = bytes((0x08,0xF7,reg,0,0))
    rx = xfer(fd, tx, 1)
    print(f"READ  8  0x{reg:02X}              = 0x{rx[0]:02X}")
    time.sleep(delay)
    return rx[0]

def rd16(fd, addr, delay=.005):
    tx = bytes((0x04,0xFB,((addr>>8)&0xff)|0x80,addr&0xff,0,1))
    rx = xfer(fd, tx, 2)
    v=(rx[0]<<8)|rx[1]
    print(f"READ 16  0x{addr:04X}            = 0x{v:04X}  raw={rx.hex(' ')}")
    time.sleep(delay)
    return v

def wr16(fd, addr, val, delay=.005):
    tx=bytes((0x05,0xFA,((addr>>8)&0xff)|0x80,addr&0xff,0,1,(val>>8)&0xff,val&0xff))
    wr(fd,f"WR16 {addr:04X}={val:04X}",tx,delay)

fd=os.open(DEV,os.O_RDWR|os.O_CLOEXEC)
try:
    print("=== FTE4800 post-HW-init verification ===")
    ioctl_reset(fd); print("IOCTL_RESET ok"); time.sleep(.020)
    wr(fd,"WAKEUP1",bytes.fromhex("ff000000"),.020)
    wr(fd,"MODE11",bytes.fromhex("70"),.100)
    wr(fd,"MODE0",bytes.fromhex("c03f00"),.050)
    wr(fd,"WAKEUP2",bytes.fromhex("ff000000"),.020)

    print("\n[RESET BASELINE]")
    rd8(fd,0x80)

    print("\n[PRE-HW]")
    wr(fd,"MODE9",bytes.fromhex("5aa500"),.005)
    s=rd8(fd,0x80,.002)
    print(f"MODE9 status = 0x{s:02X}")
    if s != 0x50: wr(fd,"MODE0",bytes.fromhex("c03f00"),.003)
    wr(fd,"MODE10",bytes.fromhex("a55a00"),.020)
    rd8(fd,0x80,.005)

    print("\n[PLL 0x03]")
    wr(fd,"WR8 F1=03",bytes.fromhex("09f6f103"))
    for v in (0xC0,0xC1,0xC0,0xC0):
        wr(fd,f"WR8 F4={v:02X}",bytes((0x09,0xF6,0xF4,v)),.010)
    rd8(fd,0xF3,.005)

    print("\n[PLL 0x13]")
    wr(fd,"WR8 F1=13",bytes.fromhex("09f6f113"))
    for v in (0xC0,0xC1,0xC0,0xC0):
        wr(fd,f"WR8 F4={v:02X}",bytes((0x09,0xF6,0xF4,v)),.010)
    rd8(fd,0xF3,.010)

    print("\n[POST-PLL VERSION CHECK]")
    vals=[]
    for i in range(10):
        v=rd8(fd,0x9B,.010)
        vals.append(v)
        print(f"attempt {i}: 0x9B=0x{v:02X}, >>2=0x{v>>2:02X}")
        if (v>>2)==0x13:
            print("VERSION_MATCH=YES")
            break
    else:
        print("VERSION_MATCH=NO")

    print("\n[16-BIT READ/WRITE DIAGNOSTICS]")
    before=rd16(fd,0x1800,.005)
    wr16(fd,0x1800,0x4FFE,.010)
    after=rd16(fd,0x1800,.005)
    wr16(fd,0x1800,0x4FFF,.010)
    trig=rd16(fd,0x1800,.005)
    chip=rd16(fd,0x85C0,.005)
    alt=rd16(fd,0x1A8B,.005)

    print("\n[SUMMARY]")
    print(f"STATUS_0x80={rd8(fd,0x80):02X}")
    print(f"READBACK_1800_BEFORE={before:04X}")
    print(f"READBACK_1800_AFTER_ARM={after:04X}")
    print(f"READBACK_1800_AFTER_TRIGGER={trig:04X}")
    print(f"CHIP_ID_RAW={chip:04X}")
    print(f"ALT_ID_RAW={alt:04X}")
finally:
    os.close(fd)
