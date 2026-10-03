#!/usr/bin/env python3
"""Hardware image capture and diagnostics tool for FTE4800/FT9368."""
from __future__ import annotations

import argparse
import ctypes
import errno
import os
import struct
import sys
import time
from pathlib import Path

DEV = "/dev/focal_moh_spi"
IOCTL_RESET = 0x8086
SPI_READ_WRITE = 0xA5
HEADER_SIZE = 5

READ_IMAGE_REQUEST = bytes((0x90, 0x80, 0x14, 0x00, 0x00, 0x00, 0x00))
NATIVE_FRAME_BYTES = 5120
COMPAT_FRAME_BYTES = 10240
FRAME_WIDTH = 64
FRAME_HEIGHT = 80

libc = ctypes.CDLL(None, use_errno=True)
libc.read.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t]
libc.read.restype = ctypes.c_ssize_t
libc.ioctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong]
libc.ioctl.restype = ctypes.c_int


def _raise_errno(op: str) -> None:
    err = ctypes.get_errno()
    raise OSError(err, f"{op}: {os.strerror(err)}")


def compat_capture_request() -> bytes:
    total_len = max(HEADER_SIZE + len(READ_IMAGE_REQUEST), NATIVE_FRAME_BYTES)
    request = bytearray(total_len)
    struct.pack_into("<BHH", request, 0, SPI_READ_WRITE, len(READ_IMAGE_REQUEST), NATIVE_FRAME_BYTES)
    request[HEADER_SIZE:HEADER_SIZE + len(READ_IMAGE_REQUEST)] = READ_IMAGE_REQUEST
    return bytes(request)


def read_frame(fd: int) -> bytes:
    """Read a raw 5120-byte native frame from the FT9368 sensor via SPI."""
    request = compat_capture_request()
    buf = (ctypes.c_ubyte * len(request)).from_buffer_copy(request)
    result = libc.read(fd, ctypes.byref(buf), len(request))
    if result < 0:
        _raise_errno("frame read")
    if result != NATIVE_FRAME_BYTES:
        raise RuntimeError(f"frame read returned {result} bytes, expected {NATIVE_FRAME_BYTES}")
    return bytes(buf[:result])


def unpack_frame(native_data: bytes) -> bytes:
    """
    Unpack 5120 8-bit native pixels into 10240 bytes of 12-bit ADC big-endian words.
    Formula: word = ((u16)pixel) << 4
    """
    if len(native_data) != NATIVE_FRAME_BYTES:
        raise ValueError(f"expected {NATIVE_FRAME_BYTES} native bytes, got {len(native_data)}")
    out = bytearray(COMPAT_FRAME_BYTES)
    for i, val in enumerate(native_data):
        adc12 = val << 4
        out[i * 2] = (adc12 >> 8) & 0xFF
        out[i * 2 + 1] = adc12 & 0xFF
    return bytes(out)


def compute_statistics(raw_data: bytes) -> dict[str, object]:
    """Compute statistical metrics over 8-bit raw frame data."""
    if not raw_data:
        raise ValueError("empty frame data")
    pixels = list(raw_data)
    n = len(pixels)
    pmin = min(pixels)
    pmax = max(pixels)
    mean = sum(pixels) / n
    variance = sum((p - mean) ** 2 for p in pixels) / n
    std = variance ** 0.5
    unique = len(set(pixels))
    nonzero = sum(1 for p in pixels if p != 0)
    has_contrast = std > 10.0 and unique > 20

    return {
        "min": pmin,
        "max": pmax,
        "mean": mean,
        "std": std,
        "unique": unique,
        "nonzero": nonzero,
        "has_contrast": has_contrast,
    }


def save_pgm(path: str | Path, width: int, height: int, data: bytes) -> None:
    """Save 8-bit raw pixel data as a binary PGM image."""
    expected = width * height
    if len(data) != expected:
        raise ValueError(f"data length {len(data)} does not match {width}x{height}={expected}")
    header = f"P5\n{width} {height}\n255\n".encode("ascii")
    Path(path).write_bytes(header + data)


def render_ascii(data: bytes, width: int = 64, height: int = 80) -> str:
    """Render 8-bit frame as compact ASCII art."""
    chars = " .:-=+*#%@"
    lines = []
    for y in range(0, height, 2):
        row = ""
        for x in range(width):
            val = data[y * width + x]
            idx = min(val * len(chars) // 256, len(chars) - 1)
            row += chars[idx]
        lines.append(row)
    return "\n".join(lines)


def reset_sensor(fd: int) -> None:
    if libc.ioctl(fd, IOCTL_RESET, 0) < 0:
        _raise_errno("reset ioctl")


def main() -> int:
    parser = argparse.ArgumentParser(description="Capture frames from FTE4800 / FT9368 sensor.")
    parser.add_argument("--device", default=DEV, help="Path to /dev/focal_moh_spi")
    parser.add_argument("--reset", action="store_true", help="Pulse hardware reset before capture")
    parser.add_argument("--pgm", type=str, default=None, help="Save frame as PGM file")
    parser.add_argument("--raw", type=str, default=None, help="Save frame as raw 8-bit binary")
    parser.add_argument("--unpack-raw", type=str, default=None, help="Save frame as 12-bit unpacked 10240-byte binary")
    parser.add_argument("--ascii", action="store_true", help="Print ASCII representation to stdout")
    parser.add_argument("--count", type=int, default=1, help="Number of frames to capture")
    parser.add_argument("--interval", type=float, default=0.1, help="Interval between frames in seconds")
    args = parser.parse_args()

    try:
        fd = os.open(args.device, os.O_RDWR | os.O_CLOEXEC)
    except OSError as exc:
        print(f"Error opening {args.device}: {exc}", file=sys.stderr)
        return 1

    try:
        if args.reset:
            reset_sensor(fd)
            print("reset: PASS (pulsed LOW, released HIGH, waiting 400ms for boot)", flush=True)
            time.sleep(0.4)

        for i in range(args.count):
            if i > 0:
                time.sleep(args.interval)

            frame = read_frame(fd)
            stats = compute_statistics(frame)
            tag = "PASS (finger contrast)" if stats["has_contrast"] else "idle/blank"
            print(
                f"frame[{i}]: {len(frame)} bytes | "
                f"range=[{stats['min']}, {stats['max']}] mean={stats['mean']:.1f} "
                f"std={stats['std']:.1f} uniq={stats['unique']} | {tag}"
            )

            if args.ascii:
                print(render_ascii(frame))

            if args.pgm:
                path = args.pgm if args.count == 1 else f"{Path(args.pgm).stem}_{i}{Path(args.pgm).suffix}"
                save_pgm(path, FRAME_WIDTH, FRAME_HEIGHT, frame)
                print(f"saved PGM: {path}")

            if args.raw:
                path = args.raw if args.count == 1 else f"{Path(args.raw).stem}_{i}{Path(args.raw).suffix}"
                Path(path).write_bytes(frame)
                print(f"saved raw: {path}")

            if args.unpack_raw:
                path = args.unpack_raw if args.count == 1 else f"{Path(args.unpack_raw).stem}_{i}{Path(args.unpack_raw).suffix}"
                unpacked = unpack_frame(frame)
                Path(path).write_bytes(unpacked)
                print(f"saved unpacked 12-bit: {path} ({len(unpacked)} bytes)")

        return 0
    finally:
        os.close(fd)


if __name__ == "__main__":
    raise SystemExit(main())
