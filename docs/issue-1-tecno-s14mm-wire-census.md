# Issue #1 wire census v2 — Tecno MegaBook S14 (FTE4800, chip-id 0xFFFF)

This is the corrected census (v2). The first evidence package collected in
this document's predecessor used a helper whose RX offsets did not match the
kernel's shared-offset semantics (`focal_raw_xfer()` advances one offset by
each step's len; the old helper returned `rx[:n]`, which prefixed seven
stale bytes and shifted the data window). The probe
(`tools/fte4800_wire_probe.py`) now mirrors the kernel exactly, and
`tests/test_wire_probe_accounting.py` locks that behavior down with unit
tests on payload alignment and clock counts.

    Machine:      TECNO MegaBook S14 (S14MM SKU), Core Ultra 9 185H, Arch Linux
    Kernel:       7.2.9-arch1-1
    ACPI device:  \_SB.PC02.SPI1.FPNT (_ADR 0x001E0003 = PCI 00:1e.3),
                  enumerated by Linux as pxa2xx-spi.2 / spi-FTE4800:00
    Driver:       focal_spi DKMS v1.0.3, source md5-identical to git main
    Selftest:     reset PASS; identity always 0xFFFF; RESULT: FAIL
                  (verified on the issue/tecno-wake-diagnostic branch, 0742fce)

## 1. Verified working (unchanged from v1)

* ACPI/DSDT: `FPTT == 0x07` -> HID `FTE4800`; `FPTM == 0` -> `_CRS` =
  SpiSerialBus (mode 0, 1 MHz) + one GpioIo reset pad + GpioInt
  (Edge, ActiveHigh) -> IRQ 66 rising edge. Kernel binding matches:
  `ready: mode=0 speed=1000000Hz bits=8 irq=66 reset=active-high`;
  `gpio-208 (GPP_B_4) out hi` claimed by `spi-FTE4800:00`.
* **The reset pad physically controls the sensor.** Reset A/B test (§2 [1]):
  the MISO line behavior differs between reset-asserted and released states.

## 2. Wire census (corrected probe)

### [1] Reset A/B test (full-duplex 32 B @1 MHz, payload window)

| State | payload census |
|---|---|
| Reset pad asserted LOW | `00×9 ff×23` |
| Reset pad released HIGH | `00×9 xx ff×22` |

With the pad LOW the line is still clamped low for ~9 bytes before floating
high — so the sensor (or its MISO pad) shows *some* activity even while held
in reset, and a *longer* clamp (~17-18 bytes) once released. This is direct
evidence that the reset pad toggling reaches the sensor side of the bus.

### [10] Window-length sweep — the clamp is byte-aligned, not time-based

Write-then-read @1 MHz, zero-prefix length vs requested window n:

| n | zero-prefix |
|---|---|
| 2, 4, 6, 8, 12, 16 | n (window ends inside the clamp) |
| 17, 18, 20, 24 | 17 |
| 32, 48, 64 | 17-18 (jitter ±1, single ramp byte) |

The clamp saturates at ~17-18 bytes and is independent of the requested
length. Combined with §[4] below (identical prefix at 100 kHz - 8 MHz), the
release is tied to the clock, i.e. a device-side state machine, not an RC
ramp.

### [3]/[4] Mode and speed sweep

Zero-prefix is ~17 bytes for every SPI mode (0-3) and every clock from
100 kHz to 8 MHz. A framing mismatch would change the pattern with mode;
an RC artifact would track time. Neither happens — the response is a fixed
byte-count of actively driven LOW, then hi-Z with a slow pull-up release.

### [2] Framing sweep

Same shape for write-then-read (two CS windows) and full-duplex (one CS
window, 7+n clocks): the clamp starts at each CS-assert and lasts ~17-18
clock bytes. The 7 header-position bytes of the full-duplex capture are also
LOW — the sensor clamps MISO while the header is being clocked in.

### [5] ROM-state ID probe

`read(0x0090)` (2 B write-then-read and 32 B full-duplex) never returns the
documented ROM bootloader ID `0x56A2`; only the fixed clamp pattern.

### [6] Vendor wake / sync variants

`FF 00 00 00` wake after reset (+5 ms), wake *while* the reset pad is LOW
then release (+5 ms / +350 ms), and `CMD_Set(0x55)` with 10/20/50/100/200/
300/500 ms waits before the identity read: all produce the identical clamp
pattern. The opt-in `--wake-probe` from 0742fce remains FAIL on this
machine. No recovery sequence changes the wire behavior.

### [8] Bulk-response profile (5120 B)

Deep reads of `0x9180` and `0x9080` and the full triggered-capture sequence
(`SFR 0x3B=1`, 60 ms integration, bulk `0x9080`): every 5120-byte payload is
`00×~10 xx ff×~5110`. No data anywhere in a 5120-byte window, for any
address, before or after the SFR trigger.

### [9] IRQ census — the sensor signals once per reset release

With the IRQ enabled (`IOCTL_IRQ_ENABLE(1)`), `/proc/interrupts` summed over
all CPUs (v1 counted only the first CPU and reported 0 — wrong):

```
IRQ count 1 -> 2, 2 -> 3, 3 -> 4, 4 -> 5   (one edge per pad release)
```

An isolated check confirms: no edges while idle, none while the pad is held
LOW, exactly one rising edge after each release. Two readings are possible:

* the sensor raises its attention line at the end of a (failed) boot attempt,
* or the edge is an electrical artifact of the pad-release transition.

Either way the line is wired and observed by the kernel.

## 3. Interpretation

Corrected model of the sensor's wire behavior:

1. attached, reset control works (pad state changes line behavior),
2. IRQ line wired and observed, exactly one edge per reset release,
3. SPI response engine: from each CS-assert, MISO is actively driven LOW
   for ~17-18 clock bytes (9 when held in reset), then released hi-Z with a
   slow pull-up charge — invariant across modes 0-3, 100 kHz - 8 MHz, every
   address (0x9180 / 0x9080 / 0x0090), every framing, and every vendor
   recovery sequence; no address- or command-dependent content anywhere,
4. never returns a valid identity (chip@0x13 = 0xFFFF in every sample).

The byte-aligned, clock-tracking clamp is a *device-side* behavior, not a
passive-line artifact. The remaining explanations:

* **H1 — SKU/board-level power or strap.** The S14MM fingerprint module may
  be missing its rail or be strapped for a different boot path, leaving the
  MCU in a non-communicating state (fixed clamp + boot-attention IRQ).
* **H2 — flex/connector fault on this specific unit.** Same signature.
* **H3 — different FocalTech sensor variant on this SKU** that requires the
  vendor PRAMBOOT firmware download handshake (CMD_Set(0x55) sync, ROM ID
  `0x56A2` gate, 0x09/0x10/0x61 config, 0x6A poll, 0xAB/0xBF download loop).
  The gate never opens here (no `0x56A2`), so the handshake cannot start
  from the current transport, and the identical clamp pattern across all
  known commands does not support a framing bug on our side.

## 4. How to reproduce

    sudo python3 tools/fte4800_wire_probe.py 2>&1 | tee wire-census-v2.log

## 5. Next steps

1. Windows behaviour on the same unit (did fingerprint enroll work in
   Windows before Arch was installed?) — splits H1/H2 from H3.
2. Logic analyser on the flex: confirm the ~17-18-byte LOW clamp is driven
   by the sensor pad (H1/H2) and check whether any clock edge count other
   than ~17-18*8 ever appears.
3. If H3 is desired to be tested further, port the PRAMBOOT handshake from
   the Windows RE into `tools/ft9368.py` as an opt-in `--pramboot` probe;
   note the `0x56A2` gate has never opened on this machine, so a successful
   port would still likely need the vendor's exact ROM-state entry sequence.
