#!/usr/bin/env python3
"""FT9368 PRAMBOOT loader following the Windows DLL boot entry sequence.

This stage only loads/reads PRAMBOOT RAM. APP flash programming is intentionally
not implemented.
"""
import argparse
import ctypes
import fcntl
import hashlib
import os
import struct
import time
from pathlib import Path

DEV = "/dev/spidev1.0"
FW = Path(__file__).resolve().parent.parent / "extracted-windows-fw" / "FT9368_PRAMBOOT.bin"

SPI_IOC_WR_MODE32 = 0x40046b05
SPI_IOC_WR_MAX_SPEED_HZ = 0x40046b04
SPI_IOC_MSG_BASE = 0x40006b00

class spi_ioc_transfer(ctypes.Structure):
    _fields_ = [
        ("tx_buf", ctypes.c_uint64),
        ("rx_buf", ctypes.c_uint64),
        ("len", ctypes.c_uint32),
        ("speed_hz", ctypes.c_uint32),
        ("delay_usecs", ctypes.c_uint16),
        ("bits_per_word", ctypes.c_uint8),
        ("cs_change", ctypes.c_uint8),
        ("tx_nbits", ctypes.c_uint8),
        ("rx_nbits", ctypes.c_uint8),
        ("word_delay_usecs", ctypes.c_uint8),
        ("pad", ctypes.c_uint8),
    ]

def SPI_IOC_MESSAGE(n):
    return SPI_IOC_MSG_BASE | ((n * 32) << 16)

def single(fd, tx_data, rx_len=0):
    txb = (ctypes.c_uint8 * len(tx_data))(*tx_data)
    rxb = (ctypes.c_uint8 * rx_len)() if rx_len else None
    t = spi_ioc_transfer()
    t.tx_buf = ctypes.addressof(txb)
    t.rx_buf = ctypes.addressof(rxb) if rxb is not None else 0
    t.len = max(len(tx_data), rx_len)
    t.speed_hz = 1_000_000
    t.bits_per_word = 8
    fcntl.ioctl(fd, SPI_IOC_MESSAGE(1), t)
    return bytes(rxb) if rxb is not None else b""

def tx(fd, data):
    single(fd, data)

def split(fd, tx_data, rx_len):
    txb = (ctypes.c_uint8 * len(tx_data))(*tx_data)
    clock = (ctypes.c_uint8 * rx_len)(*([0] * rx_len))
    rxb = (ctypes.c_uint8 * rx_len)()
    xfers = (spi_ioc_transfer * 2)()

    xfers[0].tx_buf = ctypes.addressof(txb)
    xfers[0].len = len(tx_data)
    xfers[0].speed_hz = 1_000_000
    xfers[0].bits_per_word = 8

    xfers[1].tx_buf = ctypes.addressof(clock)
    xfers[1].rx_buf = ctypes.addressof(rxb)
    xfers[1].len = rx_len
    xfers[1].speed_hz = 1_000_000
    xfers[1].bits_per_word = 8

    fcntl.ioctl(fd, SPI_IOC_MESSAGE(2), xfers)
    return bytes(rxb)

def wake(fd):
    # SPI0_Wakeup observed from the Windows path / already proven on this sensor.
    tx(fd, [0xFF, 0x00, 0x00, 0x00])

def spi_cmd_set(fd, cmd):
    # fcn.18001b684: SPI0_CMD_Set(cmd)
    # Local 4-byte buffer is [cmd, 0, 0, 0], after SPI0_Wakeup().
    print(f"SPI0_CMD_Set(0x{cmd:02x}) -> {cmd:02x} 00 00 00")
    wake(fd)
    tx(fd, [cmd, 0x00, 0x00, 0x00])

def read8(fd, reg):
    # SPI0_Read8: [08 f7 reg 00 00], then 1-byte RX with CS held.
    rx = split(fd, [0x08, 0xF7, reg & 0xFF, 0x00, 0x00], 1)
    return rx[0]

def write8(fd, reg, value):
    # SPI0_Write8: [09 f6 reg value].
    tx(fd, [0x09, 0xF6, reg & 0xFF, value & 0xFF])

def read16(fd, addr):
    # Reference SPI0_Read16 transaction: [04 fb addr_hi|80 addr_lo 00 01],
    # followed by 2-byte RX while CS remains asserted.
    ah = ((addr >> 8) & 0xFF) | 0x80
    al = addr & 0xFF
    rx = split(fd, [0x04, 0xFB, ah, al, 0x00, 0x01], 2)
    return (rx[0] << 8) | rx[1]

def iic_sfr_write_packet(addr, value):
    return [
        0x70, 0x07, 0xF8,
        (addr >> 8) & 0xFF, addr & 0xFF,
        0x00, 0x00,
        (value >> 8) & 0xFF, value & 0xFF,
        0x00, 0x00,
    ]

def boot_entry(fd):
    # fcn.18001be1c, before any PRAMBOOT RAM write:
    #   SPI0_CMD_Set(0x55)
    #   Sleep(10 ms)
    #   SPI0_Read_SPI(0x90, 2) == 0x56A2
    spi_cmd_set(fd, 0x55)
    time.sleep(0.010)

    raw = split(fd, [0x04, 0xFB, 0x80, 0x90, 0x00, 0x01], 2)
    probe = (raw[0] << 8) | raw[1]
    print(f"probe 0x0090 = 0x{probe:04x} (expected 0x56a2)")
    if probe != 0x56A2:
        raise RuntimeError(
            f"Windows boot-entry check failed: 0x{probe:04x} != 0x56a2; "
            "refusing to write PRAMBOOT"
        )

    print("boot-entry check passed")

    # fcn.18001be1c:
    #   SPI0_Write8(0x09, 0x0A)
    #   SPI0_Write8(0x10, 0x0C)
    #   SPI0_Write8(0x61, 0x00)
    write8(fd, 0x09, 0x0A)
    write8(fd, 0x10, 0x0C)
    write8(fd, 0x61, 0x00)

    time.sleep(0.001)

    check = read16(fd, 0xF0AA)
    print(f"check 0xf0aa = 0x{check:04x} (expected 0xf0aa)")
    if check != 0xF0AA:
        raise RuntimeError(
            f"Windows boot-entry second check failed: 0x{check:04x} != 0xf0aa; "
            "refusing to write PRAMBOOT"
        )
    print("bootloader RAM-write entry state passed")

def fw_write(fd, addr, data):
    if len(data) % 4:
        raise ValueError("firmware chunk must be 4-byte aligned")
    nwords = len(data) // 4
    if not 1 <= nwords <= 0x100:
        raise ValueError("invalid firmware chunk length")
    hdr = [
        0x70, 0x05, 0xFA,
        (addr >> 8) & 0xFF, addr & 0xFF,
        ((nwords - 1) >> 8) & 0xFF, (nwords - 1) & 0xFF,
    ]
    tx(fd, hdr + list(data))

def fw_read(fd, addr, nbytes):
    if nbytes % 4 or not 1 <= nbytes // 4 <= 0x100:
        raise ValueError("invalid firmware read length")
    nwords_minus1 = (nbytes // 4) - 1
    cmd = [
        0x70, 0x04, 0xFB,
        (addr >> 8) & 0xFF, addr & 0xFF,
        (nwords_minus1 >> 8) & 0xFF, nwords_minus1 & 0xFF,
    ]
    # fcn.18001af74: command TX, then a read phase beginning with 0x71,
    # with CS held across both phases. Payload begins at returned byte 1.
    n = nbytes + 1
    txb = (ctypes.c_uint8 * len(cmd))(*cmd)
    phase_tx = (ctypes.c_uint8 * n)(*([0x71] + [0] * nbytes))
    phase_rx = (ctypes.c_uint8 * n)()
    xfers = (spi_ioc_transfer * 2)()

    xfers[0].tx_buf = ctypes.addressof(txb)
    xfers[0].len = len(cmd)
    xfers[0].speed_hz = 1_000_000
    xfers[0].bits_per_word = 8

    xfers[1].tx_buf = ctypes.addressof(phase_tx)
    xfers[1].rx_buf = ctypes.addressof(phase_rx)
    xfers[1].len = n
    xfers[1].speed_hz = 1_000_000
    xfers[1].bits_per_word = 8

    fcntl.ioctl(fd, SPI_IOC_MESSAGE(2), xfers)
    return bytes(phase_rx)[1:]

def finish(fd):
    # fcn.18001aa98 tail.
    tx(fd, iic_sfr_write_packet(0x0007, 0x5A5A))
    tx(fd, [0x70, 0x0A, 0xF5])
    time.sleep(0.010)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", action="store_true", help="actually perform PRAMBOOT upload")
    args = ap.parse_args()

    data = FW.read_bytes()
    sha = hashlib.sha256(data).hexdigest()

    print(f"PRAMBOOT: {FW}")
    print(f"size={len(data)} sha256={sha}")

    if len(data) != 6096:
        raise SystemExit("Refusing: expected exact 6096-byte PRAMBOOT")

    if not args.run:
        print("DRY RUN: no SPI I/O")
        return

    fd = os.open(DEV, os.O_RDWR)
    try:
        fcntl.ioctl(fd, SPI_IOC_WR_MODE32, struct.pack("I", 0))
        fcntl.ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, struct.pack("I", 1_000_000))

        boot_entry(fd)

        for off in range(0, len(data), 128):
            chunk = data[off:off + 128]
            addr = 0x2000 + off // 4
            fw_write(fd, addr, chunk)
            print(f"write {off:5d}/{len(data)} addr=0x{addr:04x}")

        for off in range(0, len(data), 256):
            chunk = data[off:off + 256]
            addr = 0x2000 + off // 4
            got = fw_read(fd, addr, len(chunk))
            if got != chunk:
                print(f"VERIFY FAIL addr=0x{addr:04x} off={off}")
                print("expected:", chunk[:32].hex(" "))
                print("got:     ", got[:32].hex(" "))
                raise SystemExit(2)
            print(f"verify {off:5d}/{len(data)} addr=0x{addr:04x}")

        finish(fd)
        print("PRAMBOOT RAM stage completed and verified; APP flash stage was NOT executed.")
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()

