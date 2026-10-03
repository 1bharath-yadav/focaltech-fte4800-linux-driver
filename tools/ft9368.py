"""FT9368 userspace protocol helper over /dev/focal_moh_spi (clean kernel driver).

Verified-on-hardware building blocks (see docs/ft9368-transport.md):
  read(addr, n)   : 7-byte header [ah, al, nh, nl, 0, 0, 0] then n bytes (write-then-read)
  wake()          : write [FF 00 00 00]  (Windows SPI0_Wakeup / WakeDevice 0xFF00)
  sfr_write(a, v) : [70 07 F8 ah al 00 00 vh vl 00 00]
  capture()       : sfr_write(0x003B, 1); ~60 ms ADC integration; read(0x9080, 5120)
"""
import os, time, struct, fcntl, ctypes

DEV = "/dev/focal_moh_spi"
IOCTL_RESET = 0x8086
W, H = 64, 80
NPIX = W * H
_libc = ctypes.CDLL("libc.so.6", use_errno=True)


class FT9368:
    def __init__(self, path=DEV):
        self.fd = os.open(path, os.O_RDWR)

    def close(self):
        os.close(self.fd)

    # --- raw transport ----------------------------------------------------
    def xfer(self, tx, rx):
        buf = bytearray(max(5 + len(tx), rx))
        buf[0] = 0xA5
        buf[1:3] = struct.pack("<H", len(tx))
        buf[3:5] = struct.pack("<H", rx)
        buf[5:5 + len(tx)] = tx
        cbuf = (ctypes.c_ubyte * len(buf)).from_buffer(buf)
        r = _libc.read(self.fd, cbuf, len(buf))
        if r < 0:
            raise OSError(ctypes.get_errno(), "read")
        return bytes(buf[:rx])

    def write(self, tx):
        buf = bytearray(5 + len(tx))
        buf[0] = 0xA5
        buf[1:3] = struct.pack("<H", len(tx))
        buf[5:] = tx
        n = os.write(self.fd, bytes(buf))
        if n != len(buf):
            raise OSError("short write")

    # --- FT9368 protocol --------------------------------------------------
    def reset(self, boot_wait=0.4):
        fcntl.ioctl(self.fd, IOCTL_RESET, 0)
        time.sleep(boot_wait)

    def wake(self, delay=0.010):
        self.write(bytes([0xFF, 0x00, 0x00, 0x00]))
        time.sleep(delay)

    def read(self, addr, n, wake=True, wake_delay=0.010):
        if wake:
            self.wake(wake_delay)
        hdr = bytes([addr >> 8, addr & 0xFF, n >> 8, n & 0xFF, 0, 0, 0])
        return self.xfer(hdr, n)

    def sfr_write(self, addr, val):
        self.write(bytes([0x70, 0x07, 0xF8, addr >> 8, addr & 0xFF, 0, 0,
                          val >> 8, val & 0xFF, 0, 0]))

    def identity(self, **kw):
        r = self.read(0x9180, 32, **kw)
        return r, (r[0x13] << 8) | r[0x14]

    def finger_status(self, **kw):
        return self.read(0x9180, 6, **kw)

    def capture(self, integ=0.060, **kw):
        self.wake()
        self.sfr_write(0x003B, 0x0001)
        time.sleep(integ)
        return self.read(0x9080, NPIX, wake=False)
