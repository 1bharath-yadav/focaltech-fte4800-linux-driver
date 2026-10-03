# FocalTech FTE4800 / FT9368 Linux Driver

Hardware-backed Linux support for FocalTech FTE4800 / FT9368 SPI fingerprint sensors. The implementation is currently validated on the Infinix ZERO BOOK 13 (ZL513).

Target ACPI device: `FTE4800:00`
Target sensor: FocalTech FT9368
Validated kernel: Linux 7.2.5-3-omarchy x86_64
Device interface: `/dev/focal_moh_spi`

## Status

The kernel transport and native libfprint integration have been exercised on real hardware.

Verified:

- ACPI/SPI probe and driver lifecycle;
- FT9368 reset and firmware boot sequence;
- sensor identification;
- real 64x80 image capture;
- five-frame enrollment;
- persistent fprintd template storage;
- genuine verification;
- different-finger rejection in the local evaluation set;
- reboot and suspend/resume recovery;
- Omarchy lock-screen fingerprint authentication with password fallback;
- clean DKMS installation and source-contract tests.

The matching threshold remains an experimental value. The current local biometric dataset is too small to establish production FAR/FRR bounds or security certification.

## Architecture

```
FTE4800 / FT9368 sensor
        |
        v
  ACPI + SPI controller
        |
        v
 focal_spi kernel transport
        |
        v
 /dev/focal_moh_spi
        |
        v
 native FTE4800 libfprint driver
        |
        v
       fprintd
        |
        v
     pam_fprintd
        |
        +--> sudo / polkit
        |
        +--> Omarchy lock screen
```

The kernel module is deliberately a transport layer. It does not fabricate fingerprint frames and does not perform biometric matching.

## Verified FT9368 protocol

Reset is active-low:

```
HIGH -> LOW for ~10 ms -> HIGH -> wait ~350 ms
```

Identity request:

```
91 80 00 20 00 00 00
```

The validated response identifies chip `0x9368`, firmware date `2022-07-29`, and image geometry `64x80`.

Physical image capture:

```
SFR write: 70 07 F8 00 3B 00 00 00 01 00 00
wait:      60 ms
read:      90 80 14 00 00 00 00
image:     5120 bytes, 64x80, 8-bit pixels
```

A plain `0x9080` read is not sufficient; the sensor must first be triggered through the verified SFR write.

Detailed protocol notes are in `docs/`.

## Kernel driver build

The driver is an out-of-tree DKMS-compatible SPI transport.

Check the system without changing it:

```bash
sudo ./install/install.sh --check
```

Install:

```bash
sudo ./install/install.sh
```

Skip the hardware self-test:

```bash
sudo ./install/install.sh --no-test
```

Remove:

```bash
sudo ./install/uninstall.sh
```

Direct build:

```bash
make
```

The kernel installer does not replace the distribution libfprint package.

## Hardware diagnostics

```bash
python3 -m unittest discover -s tests -v
sudo python3 tools/fte4800_selftest.py --reset
sudo python3 tools/fte4800_capture.py --reset --pgm frame.pgm
sudo python3 tools/fte4800_capture.py --reset --count 10 --raw frame.bin
sudo python3 tools/live-finger-monitor.py
```

## libfprint integration

The repository contains a downstream patch in `libfprint-patches/`.

Base commit:

```
396119347a6947efc6a43edc4708d5581dd13686
```

Build the separate libfprint checkout:

```bash
./install/build-libfprint.sh /path/to/libfprint-upstream
```

For the validated ZERO BOOK deployment, the native library is installed under:

```
/opt/fte4800/libfprint/lib/libfprint-2.so.2.0.0
```

Only the fprintd service is directed to this library through a systemd drop-in. The distribution files in `/usr/lib` are retained.

See `docs/libfprint-upstream.md` before preparing an upstream merge request.

## Native matcher

The FT9368 provides only 64x80 imaging data. The current driver retains five individual raw enrollment frames and compares a probe against the stored samples.

The matcher applies:

- local background and ridge normalization;
- a validity mask;
- rotation search from -24 degrees to +24 degrees in 4-degree steps;
- translation search with bounded offsets;
- overlap-aware normalized correlation;
- best-of-five template scoring.

The current threshold is `0.75`. It is explicitly a research threshold and is not security-certified.

The matcher specification and reference implementation are in `tools/matcher_ref.py`.

## Omarchy integration

Omarchy's normal fingerprint setup is designed around its system package flow. The project includes a FTE4800-aware local wrapper so this laptop can use the native libfprint build without replacing it.

Important: the stock Omarchy setup command may install or replace libfprint packages. Use the project wrapper when validating this FTE4800 deployment.

The long-term upstream work belongs in Omarchy and libfprint rather than in this kernel driver repository. See `docs/omarchy-integration.md`.

## Repository hygiene

The public Git tree intentionally excludes:

- generated kernel build artifacts;
- local biometric captures;
- proprietary Windows driver packages and extracted firmware;
- raw ACPI dumps;
- internal agent instructions;
- legacy reverse-engineering copies whose redistribution status is not established.

Those files are preserved locally under the root `archive/` directory.

## License

The kernel transport is GPL-2.0-only.

The downstream libfprint driver and matcher patch is LGPL-2.1-or-later to match the libfprint component being modified.

License texts are provided under `LICENSES/`, and source files carry SPDX identifiers where applicable.

## Security

This project is experimental biometric infrastructure. It is not security-certified. Do not treat the current matcher measurements as production biometric guarantees.

See `SECURITY.md` for reporting guidance.
