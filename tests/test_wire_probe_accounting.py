"""Unit tests for tools/fte4800_wire_probe.py — kernel-offset accounting.

The focal_spi driver (focal_raw_xfer) shares one byte offset between the tx
and rx buffers and advances it by each step's len; every step clocks exactly
len bytes. When the rx buffer is enabled for a step, the whole transfer is
captured into req.rx[offset : offset + len]. These tests mirror that
semantics and verify payload alignment and clock counts without hardware.
"""
import struct
import unittest

from tools.fte4800_wire_probe import (
    CHIP_OFFSET,
    INFO_BYTES,
    INFO_REG,
    RAW_NORX,
    RAW_NOTX,
    ROM_ID_REG,
    WAKE_PATTERN,
    RawPlan,
)


def simulate_kernel_capture(steps, sentinel=0xAA):
    """Model focal_raw_xfer()'s buffer placement: tx and rx share one offset
    that advances by each step's len. A step writes its tx bytes into the
    (simulated) tx area and, when the rx buffer is enabled, its captured
    bytes are marked 'R' in the shared capture region."""
    total = sum((0 if tx is None else len(tx)) + rxlen for tx, rxlen, _, _ in steps)
    capture = bytearray([sentinel]) * total
    offset = 0
    for tx, rxlen, _du, _cs in steps:
        txlen = 0 if tx is None else len(tx)
        step_len = txlen + rxlen
        if rxlen:
            capture[offset : offset + step_len] = [ord("R")] * step_len
        elif txlen:
            capture[offset : offset + step_len] = [ord("T")] * step_len
        offset += step_len
    return bytes(capture)


class WireProbeAccountingTests(unittest.TestCase):
    def build_plan(self, steps):
        return RawPlan(steps)

    def test_wtr_step_lengths_and_flags(self):
        """write-then-read: step0 = 7B TX-only (NORX), step1 = RX-only (NOTX)."""
        hdr = bytes((INFO_REG >> 8, INFO_REG & 0xFF, 0x00, INFO_BYTES, 0, 0, 0))
        plan = self.build_plan([(hdr, 0, 1, 1), (None, INFO_BYTES, 0, 0)])
        x = plan.request.x
        self.assertEqual(x[0].len, 7)
        self.assertEqual(x[0].flags, RAW_NORX)
        self.assertEqual(x[1].len, INFO_BYTES)
        self.assertEqual(x[1].flags, RAW_NOTX)
        self.assertEqual(plan.total_clocks, 7 + INFO_BYTES)

    def test_wtr_payload_alignment_matches_shared_offset(self):
        """The kernel places step1's capture at rx[7 : 7 + 32]; the plan's
        window must point there, not at rx[0 : 32]."""
        hdr = bytes((INFO_REG >> 8, INFO_REG & 0xFF, 0x00, INFO_BYTES, 0, 0, 0))
        steps = [(hdr, 0, 1, 1), (None, INFO_BYTES, 0, 0)]
        plan = self.build_plan(steps)
        capture = simulate_kernel_capture(steps)
        self.assertEqual(plan.windows, [(7, INFO_BYTES)])
        payload = plan.payload(capture)
        self.assertEqual(payload, b"R" * INFO_BYTES)

    def test_fdx_clock_length_is_7_plus_n(self):
        """Full-duplex: TX = header + n zeros, exactly 7 + n clocks (not
        7 + 2n); the payload window is capture[7 : 7 + n]."""
        hdr = bytes((INFO_REG >> 8, INFO_REG & 0xFF, 0x00, INFO_BYTES, 0, 0, 0))
        steps = [(hdr, INFO_BYTES, 0, 0)]
        plan = self.build_plan(steps)
        x = plan.request.x
        self.assertEqual(x[0].len, 7 + INFO_BYTES)
        self.assertEqual(x[0].flags, 0)  # both tx and rx buffers enabled
        self.assertEqual(plan.total_clocks, 7 + INFO_BYTES)
        capture = simulate_kernel_capture(steps)
        self.assertEqual(plan.windows, [(0, 7 + INFO_BYTES)])
        window = plan.payload(capture)
        self.assertEqual(len(window), 7 + INFO_BYTES)
        self.assertEqual(window[7 : 7 + INFO_BYTES], b"R" * INFO_BYTES)
        self.assertEqual(window[:7], b"R" * 7)  # header-position region

    def test_fdx_tx_padding_is_present_for_payload_window(self):
        """The TX side of the fdx step must contain the header plus exactly
        n zero bytes, so the controller clocks 7 + n bytes of header+zeros."""
        hdr = bytes((INFO_REG >> 8, INFO_REG & 0xFF, 0x00, INFO_BYTES, 0, 0, 0))
        plan = self.build_plan([(hdr, INFO_BYTES, 0, 0)])
        req = plan.request
        tx = bytes(req.tx[0 : plan.total_clocks])
        self.assertEqual(tx, hdr + bytes(INFO_BYTES))

    def test_rxonly_step(self):
        plan = self.build_plan([(None, 64, 0, 0)])
        x = plan.request.x
        self.assertEqual(x[0].len, 64)
        self.assertEqual(x[0].flags, RAW_NOTX)
        self.assertEqual(plan.total_clocks, 64)
        capture = simulate_kernel_capture([(None, 64, 0, 0)])
        self.assertEqual(plan.payload(capture), b"R" * 64)

    def test_rom_probe_shape(self):
        hdr = bytes((ROM_ID_REG >> 8, ROM_ID_REG & 0xFF, 0x00, 0x02, 0, 0, 0))
        plan = self.build_plan([(hdr, 0, 1, 1), (None, 2, 0, 0)])
        self.assertEqual(plan.total_clocks, 9)
        self.assertEqual(plan.windows, [(7, 2)])

    def test_wake_pattern_exact_bytes(self):
        self.assertEqual(WAKE_PATTERN, bytes((0xFF, 0x00, 0x00, 0x00)))

    def test_chip_offset_within_payload(self):
        self.assertLess(CHIP_OFFSET, INFO_BYTES)
        self.assertEqual(CHIP_OFFSET, 0x13)


if __name__ == "__main__":
    unittest.main()
