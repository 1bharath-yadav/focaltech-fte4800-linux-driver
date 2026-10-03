# ZeroBook FocalTech FTE4800 / FT9368 Linux Driver

Hardware target: Infinix ZERO BOOK 13 (ZL513), ACPI device `FTE4800:00`.
Sensor: FocalTech FTE4800 / FT9368.
Validated kernel: Linux 7.2.5-3-omarchy x86_64.

## Architecture

The project has two layers:

1. `focal_spi.c` is a small hardware-backed SPI transport. It does not synthesize fingerprint data or emulate vendor registers.
2. `libfprint-patches/0001-native-fte4800-ft9368-driver.patch` adds the native FT9368 image driver and research matcher to libfprint.

The transport exposes `/dev/focal_moh_spi`.

## Verified FT9368 protocol

Reset is active-low: assert LOW for 10 ms, release HIGH, then allow about 350 ms for application firmware to boot.

Identity request:

```
91 80 00 20 00 00 00
```

Verified response identifies chip `0x9368`, firmware date `2022-07-29`, and geometry `64x80`.

Physical image capture is:

```
SFR:    70 07 F8 00 3B 00 00 00 01 00 00
wait:   60 ms
read:   90 80 14 00 00 00 00
image:  5120 bytes, 64x80, 8-bit pixels
```

A plain `0x9080` read is not sufficient; the FT9368 must first be triggered with the SFR write.

## Kernel installation

Prerequisites are DKMS, matching kernel headers, Python 3, and an ACPI device exposing `FTE4800`.

Check without changing the system:

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

The installer only installs the kernel transport. It does not overwrite the distro libfprint library or modify PAM.

## Hardware tests

```bash
python3 -m unittest discover -s tests -v
sudo python3 tools/fte4800_selftest.py --reset
sudo python3 tools/fte4800_capture.py --reset --pgm frame.pgm
sudo python3 tools/fte4800_capture.py --reset --count 10 --raw frame.bin
sudo python3 tools/live-finger-monitor.py
```

## Live native libfprint test

Build the native libfprint tree first, then run:

```bash
tools/live-native-test.sh
```

This test does not replace the package-managed libfprint library. It links against the project build and exercises the real `/dev/focal_moh_spi` device. During enrollment, place the same finger for five stages and lift completely between stages. It then performs three same-finger verification attempts.

## Building native libfprint

The libfprint patch is based on commit:

```
396119347a6947efc6a43edc4708d5581dd13686
```

from the upstream libfprint GitLab repository.

Build the matching source:

```bash
git clone https://gitlab.freedesktop.org/libfprint/libfprint.git libfprint-upstream
cd libfprint-upstream
git checkout 396119347a6947efc6a43edc4708d5581dd13686
git apply /path/to/fte4800-clean-driver/libfprint-patches/0001-native-fte4800-ft9368-driver.patch
```

The repository helper builds it with documentation disabled, so gtk-doc is not required:

```bash
./install/build-libfprint.sh /path/to/libfprint-upstream
```

For the current ZERO BOOK deployment, install the project-built library under a dedicated prefix and make only the fprintd service use it:

```bash
./install/install-native-fte4800.sh
```

This leaves the distro `libfprint` package files in `/usr/lib` untouched. The service override uses `LD_LIBRARY_PATH` so the native FTE4800 library is selected by fprintd without replacing the package-managed library.

The installed library is still a research build. Complete live enrollment/verification and multi-finger threshold validation before treating it as a production biometric stack.

The build output is placed in the configured build directory.

## Native matcher

The native driver stores five individual raw enrollment frames. It does not average them into one blurred image.

Matching uses:

- local ridge/background normalisation
- a validity mask
- rotation search from -24° to +24° in 4° steps
- translation search
- overlap-aware normalized correlation
- the best score across the five stored samples

Current research threshold: `0.75`.

This threshold is not security-certified. The current two-finger replay dataset contains 38 recorded frames. At the current threshold, the native libfprint replay accepted 16/20 held-out genuine frames and 0/13 impostor frames. That dataset is too small to establish production FAR/FRR bounds.

## Native end-to-end test

`tools/vendor-emulator/` contains a user-space replay harness that feeds recorded real sensor frames to libfprint. It is not a synthetic fingerprint generator.

The current replay proves that:

- the native FTE4800 driver opens the device;
- the physical FT9368 capture sequence is represented correctly;
- five real enrollment frames can be serialized into an `FpPrint`;
- the rotation/translation-aware matcher runs through libfprint;
- genuine and impostor decisions are produced without the proprietary vendor blob.

## Live validation still required

Before enabling normal fingerprint login, collect a larger dataset:

- at least 20–30 separate placements for finger A
- at least 20–30 placements for finger B
- preferably a third finger
- full lift/repress cycles and varied placement

Then measure genuine and impostor score distributions, FAR, FRR, and the operating threshold.

The current 38-frame, two-finger dataset is an engineering dataset, not a security validation set.

## Troubleshooting

No `/dev/focal_moh_spi`:

```bash
ls /sys/bus/acpi/devices | grep FTE4800
lsmod | grep focal_spi
dmesg | grep -i focal
```

Identity failure:

```bash
sudo python3 tools/fte4800_selftest.py --reset
```

Flat image:

Make sure the capture path performs the SFR `0x003B=0x0001` trigger and waits about 60 ms before reading `0x9080`.

Do not load historical driver variants containing `generate_synthetic_frame`, `stage_shifts`, `fp_sqrt`, or other fabricated frame logic.

## Scope and current status

Completed: ACPI/SPI transport, reset sequencing, real FT9368 identification, hardware capture trigger/read, DKMS packaging, source-contract tests, native libfprint compilation, offline matcher integration, fprintd installation/runtime integration, live five-frame enrollment, persistent template storage, and live same-finger verification.

Still required for a release: larger multi-finger biometric validation, explicit different-finger rejection testing, reboot and suspend/resume testing, threshold/score validation, PAM integration for fingerprint login, and clean packaging/reproducible installation.

The clean kernel transport is intentionally independent of the proprietary Windows fingerprint library.
