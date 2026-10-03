#!/usr/bin/env python3
from __future__ import annotations

import ctypes
import os
import struct
import sys
import time

DEV = "/dev/focal_moh_spi"
RESET_IOCTL = 0x8086
SPI_READ_WRITE = 0xA5
WAKE = bytes.fromhex("ff 00 00 00")
READ16 = bytes.fromhex("04 fb 91 80 00 10")
RX_LEN = 32

libc = ctypes.CDLL(None, use_errno=True)
libc.ioctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong]
libc.ioctl.restype = ctypes.c_int
libc.read.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
libc.read.restype = ctypes.c_ssize_t
libc.write.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
libc.write.restype = ctypes.c_ssize_t


def die_errno(label: str) -> None:
    err = ctypes.get_errno()
    raise OSError(err, f"{label}: errno={err}")


def ioctl(fd: int, command: int) -> None:
    if libc.ioctl(fd, command, 0) < 0:
        die_errno("ioctl")


def write_request(fd: int, payload: bytes) -> None:
    request = struct.pack("<BHH", SPI_READ_WRITE, len(payload), 0) + payload
    buf = (ctypes.c_ubyte * len(request)).from_buffer_copy(request)
    n = libc.write(fd, ctypes.byref(buf), len(request))
    if n < 0:
        die_errno("write")
    if n != len(request):
        raise RuntimeError(f"short write: {n}/{len(request)}")


def read_request(fd: int, payload: bytes, rx_len: int) -> bytes:
    count = max(5 + len(payload), rx_len)
    request = bytearray(count)
    struct.pack_into("<BHH", request, 0, SPI_READ_WRITE, len(payload), rx_len)
    request[5:5 + len(payload)] = payload
    buf = (ctypes.c_ubyte * len(request)).from_buffer_copy(request)
    n = libc.read(fd, ctypes.byref(buf), len(request))
    if n < 0:
        die_errno("read")
    if n != rx_len:
        raise RuntimeError(f"short read: {n}/{rx_len}")
    return bytes(buf[:n])


fd = os.open(DEV, os.O_RDWR | os.O_CLOEXEC)
try:
    ioctl(fd, RESET_IOCTL)
    write_request(fd, WAKE)
    time.sleep(0.005)
    data = read_request(fd, READ16, RX_LEN)
    print(f"wake_tx: {WAKE.hex(' ')}")
    print(f"read16_tx: {READ16.hex(' ')}")
    print(f"rx_len: {RX_LEN}")
    print(f"rx: {data.hex(' ')}")
    print(f"chip_at_19: {data[19:21].hex(' ')}")
finally:
    os.close(fd)
