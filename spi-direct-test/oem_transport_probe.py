#!/usr/bin/env python3
import ctypes, fcntl, os, struct, time
DEV='/dev/spidev1.0'
SPI_IOC_WR_MODE32=0x40046b05
SPI_IOC_WR_MAX_SPEED_HZ=0x40046b04
SPI_IOC_MSG_BASE=0x40006b00
class spi_ioc_transfer(ctypes.Structure):
    _fields_=[('tx_buf',ctypes.c_uint64),('rx_buf',ctypes.c_uint64),('len',ctypes.c_uint32),('speed_hz',ctypes.c_uint32),('delay_usecs',ctypes.c_uint16),('bits_per_word',ctypes.c_uint8),('cs_change',ctypes.c_uint8),('tx_nbits',ctypes.c_uint8),('rx_nbits',ctypes.c_uint8),('word_delay_usecs',ctypes.c_uint8),('pad',ctypes.c_uint8)]
def IOC(n): return SPI_IOC_MSG_BASE|((n*32)<<16)
def one(fd, data, rxlen=0):
    a=(ctypes.c_uint8*len(data))(*data); b=(ctypes.c_uint8*rxlen)() if rxlen else None; t=spi_ioc_transfer(); t.tx_buf=ctypes.addressof(a); t.rx_buf=ctypes.addressof(b) if b else 0; t.len=max(len(data),rxlen); t.speed_hz=1_000_000; t.bits_per_word=8; fcntl.ioctl(fd,IOC(1),t); return bytes(b) if b else b''
def two(fd, tx, rxlen):
    a=(ctypes.c_uint8*len(tx))(*tx); z=(ctypes.c_uint8*rxlen)(); b=(ctypes.c_uint8*rxlen)(); x=(spi_ioc_transfer*2)(); x[0].tx_buf=ctypes.addressof(a); x[0].len=len(tx); x[0].speed_hz=1_000_000; x[0].bits_per_word=8; x[1].tx_buf=ctypes.addressof(z); x[1].rx_buf=ctypes.addressof(b); x[1].len=rxlen; x[1].speed_hz=1_000_000; x[1].bits_per_word=8; fcntl.ioctl(fd,IOC(2),x); return bytes(b)
def seq(fd, label, fn):
    try: r=fn(); print(f'{label}: {r.hex(" ") if isinstance(r,(bytes,bytearray)) else r}'); return r
    except Exception as e: print(f'{label}: ERROR {e}'); return None
fd=os.open(DEV,os.O_RDWR)
try:
    fcntl.ioctl(fd,SPI_IOC_WR_MODE32,struct.pack('I',0)); fcntl.ioctl(fd,SPI_IOC_WR_MAX_SPEED_HZ,struct.pack('I',1_000_000))
    print('=== Windows SPI0_Read_SPI transport probe ===')
    one(fd,[0xff,0,0,0]); time.sleep(.010)
    print('wakeup -> ff 00 00 00')
    one(fd,[0x55,0,0,0]); time.sleep(.010)
    print('cmdset -> 55 00 00 00')
    # fcn.18001b9ec constructs exactly 7 bytes: [reg, 0x80, len_hi, len_lo, 0, 0, 0].
    cmd=[0x90,0x80,0x00,0x02,0x00,0x00,0x00]
    raw=two(fd,cmd,2)
    print('SPI0_Read_SPI(0x90,2) raw rx =',raw.hex(' '))
    print('BE16 = 0x%04x' % ((raw[0]<<8)|raw[1]))
finally:
    os.close(fd)
