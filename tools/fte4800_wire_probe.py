#!/usr/bin/env python3
"""FTE4800 / FT9368 SPI state-changing wire-census probe (issue #1, Tecno S14).

This is NOT a read-only tool. It is a diagnostic probe with side effects:

  * toggles the reset pad (IOCTL_POWER_OFF / IOCTL_POWER_ON / IOCTL_RESET),
  * temporarily changes SPI mode and speed (IOCTL_RAW_XFER restores both),
  * enables and disables the sensor IRQ,
  * writes the vendor wake pattern, CMD_Set(0x55) and one SFR write.

It never writes firmware and never touches the production driver. It
complements tools/fte4800_selftest.py by exercising the wire below the
misc-device ABI via the kernel driver's IOCTL_RAW_XFER (0x80A0).

Kernel offset semantics (focal_spi.c, focal_raw_xfer): the tx and rx
pointers share ONE byte offset that advances by each step's len
(`offset += step->len`). A step clocks exactly `len` bytes; when the rx
buffer is enabled (flag RAW_NORX not set) the whole transfer is captured
into req.rx[offset : offset+len]. build_raw_request() mirrors that
semantics and the unit tests verify payload alignment and clock counts
against it.

  * A/B reset-state test      - identity read with the reset pad held LOW
                                versus released.
  * Framing sweep             - write-then-read (two CS windows) vs two-phase
                                full-duplex (one CS window) vs raw RX-only.
  * Mode / speed sweep        - SPI modes 0-3, speeds 100 kHz - 8 MHz.
  * ROM-state ID probe        - read 0x0090, expect 0x56A2 while in ROM boot.
  * Vendor-wake variants      - FF 00 00 00 write before/after reset (the
                                SPI0_Wakeup pattern reverse engineered from
                                ftWbioUmdfDriverV2.dll), and CMD_Set(0x55).
  * Boot-timing sweep         - identity reads from ~10 ms to ~800 ms after
                                reset release, using our own pad toggling
                                (IOCTL_RESET itself blocks ~350 ms).
  * Bulk-response profile     - 5120-byte reads of 0x9180 / 0x9080 with a
                                run-length census (FF / 00 / mid-level bytes).
  * IRQ census                - enable the sensor IRQ and count edges during
                                reset toggles (summed over all CPUs).

Interpretation used by docs/issue-1-tecno-s14mm-wire-census.md:
  A healthy FT9368 answers identity reads at 0x9180 with
  '00 00 ff 00 .. .. 29 93 68 11 aa 40 50 ..' (chip id 0x9368). A sensor
  that is held in reset answers 0xFF. A sensor that never parses commands
  still presents a fixed, address-independent line-level artifact.
"""
from __future__ import annotations

import argparse
import ctypes
import os
import time

DEV = "/dev/focal_moh_spi"

IOCTL_RESET = 0x8086
IOCTL_POWER_OFF = 0x8087
IOCTL_POWER_ON = 0x8088
IOCTL_IRQ_ENABLE = 0x8089
IOCTL_RAW_XFER = 0x80A0

RAW_XFER_MAX = 16
RAW_XFER_BUF = 16384
RAW_NOTX = 0x01
RAW_NORX = 0x02

INFO_REG = 0x9180
IMAGE_REG = 0x9080
ROM_ID_REG = 0x0090
INFO_BYTES = 32
CHIP_OFFSET = 0x13
CHIP_ID = 0x9368

WAKE_PATTERN = bytes((0xFF, 0x00, 0x00, 0x00))  # SPI0_Wakeup (4-byte, no RX)
CMD_SET_55 = bytes((0x70, 0x55, 0xAA))          # CMD_Set(0x55), sync/prepare
SFR_WRITE = 0x70, 0x07, 0xF8                    # CMD_Set(0x07), SFR write

IRQ_PROC = "/proc/interrupts"

libc = ctypes.CDLL(None, use_errno=True)
libc.ioctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_void_p]
libc.ioctl.restype = ctypes.c_int


class RawStep(ctypes.Structure):
    _fields_ = [
        ("len", ctypes.c_uint32),
        ("delay_us", ctypes.c_uint16),
        ("cs_change", ctypes.c_uint8),
        ("flags", ctypes.c_uint8),
    ]


class RawRequest(ctypes.Structure):
    _fields_ = [
        ("n", ctypes.c_uint32),
        ("mode", ctypes.c_uint32),
        ("speed_hz", ctypes.c_uint32),
        ("pre_delay_us", ctypes.c_uint32),
        ("x", RawStep * RAW_XFER_MAX),
        ("tx", ctypes.c_uint8 * RAW_XFER_BUF),
        ("rx", ctypes.c_uint8 * RAW_XFER_BUF),
    ]


class RawPlan:
    """Pure, kernel-mirroring plan for one IOCTL_RAW_XFER.

    steps: list of (tx|None, rxlen, delay_us, cs_change). A step's transfer
    length is txlen + rxlen, exactly as focal_raw_xfer() advances its shared
    offset by step->len. When rxlen > 0 the transfer is captured into the
    rx buffer at the shared offset; windows records (offset, len) pairs of
    the captured regions, so payload = concat(capture[o : o + l]).
    """

    def __init__(self, steps):
        self.windows: list[tuple[int, int]] = []
        self.total_clocks = 0
        self.total_tx = 0
        req = RawRequest()
        req.n = len(steps)
        self._req = req
        offset = 0
        for i, (tx, rxlen, delay_us, cs) in enumerate(steps):
            txlen = 0 if tx is None else len(tx)
            req.x[i].len = txlen + rxlen
            req.x[i].delay_us = delay_us
            req.x[i].cs_change = 1 if cs else 0
            flags = 0
            if txlen == 0:
                flags |= RAW_NOTX
            if rxlen == 0:
                flags |= RAW_NORX
            req.x[i].flags = flags
            if tx:
                for j, byte in enumerate(tx):
                    req.tx[offset + j] = byte
                if rxlen:  # pad the TX side of a full-duplex step
                    req.tx[offset + txlen : offset + txlen + rxlen] = bytes(rxlen)
            if rxlen:
                pass  # (window recorded below with the full step length)
            if flags & RAW_NORX == 0:
                # the whole transfer is captured into the rx buffer
                self.windows.append((offset, txlen + rxlen))
            offset += txlen + rxlen
        self.total_clocks = offset

    @property
    def request(self) -> RawRequest:
        return self._req

    def payload(self, capture: bytes) -> bytes:
        """Concatenated rx-buffer capture regions (kernel-faithful lengths).

        Each window holds exactly step->len bytes: for write-then-read the
        RX-only step's window IS the payload; for full-duplex the window
        carries the 7 header-position bytes first, so framings slice
        payload[7 : 7 + n] for the payload proper.
        """
        return b"".join(capture[o : o + l] for o, l in self.windows)


class Wire:
    """IOCTL_RAW_XFER wrapper with kernel-faithful offset accounting."""

    def __init__(self, path: str = DEV):
        self.fd = os.open(path, os.O_RDWR)

    def close(self) -> None:
        os.close(self.fd)

    def raw(self, steps, mode: int = 0xFFFFFFFF, speed_hz: int = 0):
        """Returns (capture, payload). capture is rx[0:total_clocks]."""
        plan = RawPlan(steps)
        req = plan.request
        buf = (ctypes.c_ubyte * ctypes.sizeof(req)).from_buffer(req)
        if libc.ioctl(self.fd, IOCTL_RAW_XFER, buf) < 0:
            raise OSError(ctypes.get_errno(), "IOCTL_RAW_XFER")
        capture = bytes(req.rx[: plan.total_clocks])
        return capture, plan.payload(capture)

    # framings -------------------------------------------------------------
    def read_wtr(self, addr: int, n: int, mode=0xFFFFFFFF, speed=0) -> bytes:
        """Verified healthy form: TX header (CS window 1) then RX (window 2).

        With the kernel's shared-offset semantics the RX payload lands at
        capture[7 : 7 + n]; that slice is returned.
        """
        hdr = bytes((addr >> 8, addr & 0xFF, (n >> 8) & 0xFF, n & 0xFF, 0, 0, 0))
        _, payload = self.raw([(hdr, 0, 1, 1), (None, n, 0, 0)], mode=mode, speed_hz=speed)
        return payload

    def read_fdx(self, addr: int, n: int, mode=0xFFFFFFFF, speed=0) -> bytes:
        """One CS window: TX = 7-byte header + n zeros, clocks = 7 + n.

        Per docs/ft9368-transport.md the RX line carries 7 dummy bytes then
        n payload bytes; returned is capture[7 : 7 + n].
        """
        hdr = bytes((addr >> 8, addr & 0xFF, (n >> 8) & 0xFF, n & 0xFF, 0, 0, 0))
        _, window = self.raw([(hdr, n, 0, 0)], mode=mode, speed_hz=speed)
        return window[7 : 7 + n]

    def read_capture(self, addr: int, n: int, mode=0xFFFFFFFF, speed=0) -> bytes:
        """The raw full-duplex capture (7 header-position bytes + n payload)."""
        hdr = bytes((addr >> 8, addr & 0xFF, (n >> 8) & 0xFF, n & 0xFF, 0, 0, 0))
        capture, _ = self.raw([(hdr, n, 0, 0)], mode=mode, speed_hz=speed)
        return capture[: 7 + n]

    def read_rxonly(self, n: int, mode=0xFFFFFFFF, speed=0) -> bytes:
        """No TX at all: MISO line census while the clock runs."""
        _, payload = self.raw([(None, n, 0, 0)], mode=mode, speed_hz=speed)
        return payload

    def write(self, tx: bytes, delay_us: int = 0) -> bytes:
        return self.raw([(tx, 0, delay_us, 1)])

    # ioctls ---------------------------------------------------------------
    def reset(self, boot_wait: float = 0.35) -> None:
        """IOCTL_RESET. Note: the kernel ioctl itself blocks ~350 ms
        (10 ms assert + boot wait) before returning."""
        libc.ioctl(self.fd, IOCTL_RESET, None)
        if boot_wait:
            time.sleep(boot_wait)

    def pad_low(self) -> None:    # reset pad asserted (active-high pad: LOW)
        libc.ioctl(self.fd, IOCTL_POWER_OFF, None)

    def pad_high(self) -> None:   # reset pad released, chip starts booting
        libc.ioctl(self.fd, IOCTL_POWER_ON, None)

    def irq(self, on: bool) -> None:
        libc.ioctl(self.fd, IOCTL_IRQ_ENABLE, ctypes.c_void_p(1 if on else 0))


def hx(b: bytes) -> str:
    return b.hex(" ")


def chip_id(r: bytes) -> int:
    return (r[CHIP_OFFSET] << 8) | r[CHIP_OFFSET + 1] if len(r) >= CHIP_OFFSET + 2 else -1


def census(r: bytes) -> str:
    runs: list[tuple[str, int]] = []
    for byte in r:
        cls = "FF" if byte == 0xFF else ("00" if byte == 0 else "XX")
        if runs and runs[-1][0] == cls:
            runs[-1] = (cls, runs[-1][1] + 1)
        else:
            runs.append((cls, 1))
    ff = sum(b == 0xFF for b in r)
    zeros = sum(b == 0 for b in r)
    mid = len(r) - ff - zeros
    short = runs if len(runs) <= 6 else runs[:3] + [("...", 0)] + runs[-2:]
    return (f"chip@0x13=0x{chip_id(r):04X} | FFs={ff} zeros={zeros} mid={mid} "
            f"| runs={short}")


def describe(label: str, r: bytes) -> None:
    print(f"{label}: {census(r)}")


# ---------------------------------------------------------------------------
# sections

def section_reset_ab(w: Wire) -> None:
    print("\n== [1] reset A/B test: MISO line level with reset pad low vs high ==")
    w.pad_low()
    time.sleep(0.05)
    r_low = w.read_fdx(INFO_REG, INFO_BYTES)
    w.pad_high()
    time.sleep(0.35)
    r_high = w.read_fdx(INFO_REG, INFO_BYTES)
    describe("  reset LOW  ", r_low)
    describe("  reset HIGH ", r_high)


def section_framing(w: Wire) -> None:
    print("\n== [2] framing sweep @1MHz mode0 ==")
    w.reset()
    describe("  write-then-read  ", w.read_wtr(INFO_REG, INFO_BYTES))
    describe("  full-duplex-xfer ", w.read_fdx(INFO_REG, INFO_BYTES))
    describe("  fdx raw capture  ", w.read_capture(INFO_REG, INFO_BYTES))
    describe("  wtr 64B          ", w.read_wtr(INFO_REG, 64))


def section_mode_speed(w: Wire) -> None:
    print("\n== [3] SPI mode sweep (write-then-read) ==")
    for m in range(4):
        w.reset(0.05)
        describe(f"  mode={m}", w.read_wtr(INFO_REG, INFO_BYTES, mode=m))
    print("== [4] SPI speed sweep (mode0) ==")
    for s in (100_000, 250_000, 500_000, 1_000_000, 2_000_000, 4_000_000, 8_000_000):
        w.reset(0.05)
        describe(f"  {s//1000:5d} kHz", w.read_wtr(INFO_REG, INFO_BYTES, speed=s))


def section_rom(w: Wire) -> None:
    print("\n== [5] ROM-state ID (0x0090, healthy ROM value 0x56A2) ==")
    w.reset()
    describe("  wtr 2B ", w.read_wtr(ROM_ID_REG, 2))
    describe("  fdx 32B", w.read_fdx(ROM_ID_REG, 32))


def section_wake(w: Wire) -> None:
    print("\n== [6] vendor wake / sync variants ==")
    # wake after reset, +5 ms
    w.reset()
    w.write(WAKE_PATTERN)
    time.sleep(0.005)
    describe("  reset -> wake -> +5ms", w.read_wtr(INFO_REG, INFO_BYTES))
    # wake while the reset pad is LOW, then release
    w.pad_low()
    time.sleep(0.02)
    w.write(WAKE_PATTERN)
    w.pad_high()
    time.sleep(0.005)
    describe("  low -> wake -> rel +5ms  ", w.read_wtr(INFO_REG, INFO_BYTES))
    describe("  low -> wake -> rel +350ms", w.read_wtr(INFO_REG, INFO_BYTES))
    # CMD_Set(0x55) boot sync, one fresh reset per labeled wait
    for wait_ms in (10, 20, 50, 100, 200, 300, 500):
        w.reset()
        w.write(CMD_SET_55, delay_us=1)
        time.sleep(wait_ms / 1000.0)
        describe(f"  reset -> CMD55 -> +{wait_ms:4d}ms",
                 w.read_wtr(INFO_REG, INFO_BYTES))


def section_boot_timing(w: Wire) -> None:
    print("\n== [7] boot-timing sweep, t measured from pad release (fdx) ==")
    for wait_ms in (10, 25, 50, 100, 150, 200, 300, 400, 600, 800):
        w.pad_low()
        time.sleep(0.02)          # assert reset for 20 ms
        w.pad_high()
        time.sleep(wait_ms / 1000.0)
        t1 = time.time()
        describe(f"  t+{wait_ms:4d}ms", w.read_fdx(INFO_REG, INFO_BYTES))
        print(f"       (read completed at pad-release + {1000*(time.time()-t1):.1f} ms)")


def section_bulk(w: Wire) -> None:
    print("\n== [8] bulk-response profile (5120 B, one CS window) ==")
    w.reset()
    for addr, label in ((INFO_REG, "0x9180 identity"), (IMAGE_REG, "0x9080 image")):
        r = w.read_fdx(addr, 5120)
        print(f"  bulk {label}: {census(r[:64])} ...")
        print(f"       full: {census(r)}")
    # the real capture sequence: SFR write, waited integration, bulk read
    sfr = bytes((SFR_WRITE[0], SFR_WRITE[1], SFR_WRITE[2],
                 0x00, 0x3B, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00))
    w.write(sfr)
    time.sleep(0.06)
    r = w.read_fdx(IMAGE_REG, 5120)
    print(f"  bulk after sfr 0x3B=1: {census(r[:64])} ...")


def section_window_sweep(w: Wire) -> None:
    print("\n== [10] window-length sweep: MISO-low run vs n (wtr @1MHz) ==")
    for n in (2, 4, 6, 8, 12, 16, 17, 18, 20, 24, 32, 48, 64):
        w.reset(0.05)
        r = w.read_wtr(INFO_REG, n)
        nz = len(r) - len(r.lstrip(b"\x00"))
        print(f"  n={n:3d}: zero_prefix={nz:3d} | {r[:8].hex(' ')}")
    print("== [11] alternate framing: physical 4-byte form fdx, 32B ==")
    for cmd in (bytes((0x06, 0xF9, 0x99, 0x05)), bytes((0x06, 0x00, 0x00, 0x05))):
        w.reset(0.05)
        _, window = w.raw([(cmd, 32, 0, 0)])
        nz = len(window) - len(window.lstrip(b"\x00"))
        print(f"  {cmd.hex(' ')}: zero_prefix={nz} | {window.hex(' ')}")


def section_irq(w: Wire) -> None:
    print("\n== [9] IRQ census during reset toggles ==")

    def irq_count() -> int:
        with open(IRQ_PROC) as fh:
            for line in fh:
                if "focal-irq" in line:
                    tokens = line.split()
                    counters = tokens[1:-2]          # per-CPU columns
                    return sum(int(c) for c in counters if c.isdigit())
        return -1

    w.irq(True)
    try:
        for _ in range(4):
            before = irq_count()
            w.pad_low()
            time.sleep(0.05)
            w.pad_high()
            time.sleep(1.0)
            print(f"  IRQ count {before} -> {irq_count()}")
    finally:
        w.irq(False)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--device", default=DEV)
    ap.add_argument("--skip", default="",
                    help="comma list of sections to skip: reset_ab,framing,"
                         "mode_speed,rom,wake,boot_timing,bulk,irq")
    args = ap.parse_args()
    skip = {s.strip() for s in args.skip.split(",") if s.strip()} - {""}

    w = Wire(args.device)
    try:
        for section in (section_reset_ab, section_framing, section_mode_speed,
                        section_rom, section_wake, section_boot_timing,
                        section_bulk, section_window_sweep, section_irq):
            if section.__name__.removeprefix("section_") in skip:
                continue
            section(w)
        print("\nWIRE PROBE DONE")
    finally:
        w.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
