#!/usr/bin/env python3
"""Real-hardware diagnostics for the verified FTE4800/FT9368 path."""
from __future__ import annotations

import argparse
import ctypes
import errno
import os
import select
import struct
import sys
from pathlib import Path

DEV = "/dev/focal_moh_spi"
IOCTL_RESET = 0x8086
IOCTL_IRQ_ENABLE = 0x8089
SPI_READ_WRITE = 0xA5
READ_REQUEST = bytes((0x08, 0xF7, 0x91, 0x00))
INFO_BYTES = 32
INFO_CHIP_OFFSET = 0x13
CHIP_ID = 0x9368
HEADER_SIZE = 5

libc = ctypes.CDLL(None, use_errno=True)
libc.read.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
libc.read.restype = ctypes.c_ssize_t
libc.ioctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong]
libc.ioctl.restype = ctypes.c_int


def _raise_errno(op: str) -> None:
    err = ctypes.get_errno()
    raise OSError(err, f"{op}: {os.strerror(err)}")


def compat_read_request() -> bytes:
    request = bytearray(INFO_BYTES)
    struct.pack_into("<BHH", request, 0, SPI_READ_WRITE, len(READ_REQUEST), INFO_BYTES)
    request[HEADER_SIZE:HEADER_SIZE + len(READ_REQUEST)] = READ_REQUEST
    return bytes(request)


def read_info(fd: int) -> bytes:
    request = compat_read_request()
    buffer = (ctypes.c_ubyte * len(request)).from_buffer_copy(request)
    result = libc.read(fd, ctypes.byref(buffer), len(request))
    if result < 0:
        _raise_errno("info read")
    if result != INFO_BYTES:
        raise RuntimeError(
            f"info read returned {result} bytes, expected {INFO_BYTES}"
        )
    return bytes(buffer[:result])


def reset_sensor(fd: int) -> None:
    if libc.ioctl(fd, IOCTL_RESET, 0) < 0:
        _raise_errno("reset ioctl")


def enable_irq(fd: int) -> None:
    if libc.ioctl(fd, IOCTL_IRQ_ENABLE, 1) < 0:
        _raise_errno("enable IRQ ioctl")


def parse_info(info: bytes) -> dict[str, object]:
    if len(info) != INFO_BYTES:
        raise ValueError(f"info buffer must be exactly {INFO_BYTES} bytes")
    chip = int.from_bytes(info[INFO_CHIP_OFFSET:INFO_CHIP_OFFSET + 2], "big")
    return {
        "chip_id": chip,
        "firmware_raw": info[0x0F:0x13].hex(),
        "width": info[0x17],
        "height": info[0x18],
    }


def drain_irq(fd: int, quiet_seconds: float) -> int:
    if quiet_seconds <= 0:
        raise ValueError("quiet_seconds must be positive")
    poller = select.poll()
    poller.register(fd, select.POLLIN)
    drained = 0
    quiet_ms = round(quiet_seconds * 1000)
    while True:
        events = poller.poll(quiet_ms)
        if not events:
            return drained
        drained += sum(1 for _, mask in events if mask & select.POLLIN)


def wait_for_irq(fd: int, timeout: float) -> bool:
    if timeout <= 0:
        raise ValueError("timeout must be positive")
    poller = select.poll()
    poller.register(fd, select.POLLIN)
    print(f"Waiting {timeout:.1f}s for the physical FTE4800 IRQ.", flush=True)
    events = poller.poll(round(timeout * 1000))
    return any(mask & select.POLLIN for _, mask in events)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", default=DEV)
    parser.add_argument("--reset", action="store_true")
    parser.add_argument("--wait-irq", action="store_true")
    parser.add_argument("--timeout", type=float, default=15.0)
    parser.add_argument("--quiet-seconds", type=float, default=3.0)
    args = parser.parse_args()

    fd = os.open(args.device, os.O_RDWR | os.O_CLOEXEC)
    try:
        if args.reset:
            reset_sensor(fd)
            print("reset: PASS", flush=True)

        info = read_info(fd)
        parsed = parse_info(info)
        print(f"info: {info.hex(' ')}")
        print(f"chip_id: 0x{parsed['chip_id']:04X}")
        print(f"firmware_raw: {parsed['firmware_raw']}")
        print(f"reported_geometry: {parsed['width']}x{parsed['height']}")

        if parsed["chip_id"] != CHIP_ID:
            print(
                f"RESULT: FAIL (unexpected physical chip ID 0x{parsed['chip_id']:04X})",
                file=sys.stderr,
            )
            return 1

        print("identity: PASS (physical FT9368 response)", flush=True)

        if args.wait_irq:
            enable_irq(fd)
            print("irq: enabled", flush=True)
            drained = drain_irq(fd, args.quiet_seconds)
            print(
                f"startup_irq_events_drained: {drained}",
                flush=True,
            )
            print(
                "NOW PLACE YOUR FINGER ON THE SENSOR. "
                f"Touch window: {args.timeout:.1f}s.",
                flush=True,
            )
            if not wait_for_irq(fd, args.timeout):
                print("RESULT: FAIL (no physical IRQ in touch window)", file=sys.stderr)
                return 1
            print(
                "RESULT: PASS (physical IRQ observed in user touch window)",
                flush=True,
            )

        return 0
    except OSError as exc:
        if exc.errno == errno.ENOENT:
            print(f"device not found: {args.device}", file=sys.stderr)
        else:
            print(f"I/O error: {exc}", file=sys.stderr)
        return 2
    finally:
        os.close(fd)


if __name__ == "__main__":
    raise SystemExit(main())
