# Development Guidance

## Timeline

This project started on 2026-10-01 as an attempt to make the FocalTech fingerprint reader on an Infinix ZERO BOOK 13 work on Linux.

Focused hardware and Windows-driver investigation started on 2026-10-02. The working baseline was completed on 2026-10-03: real FT9368 capture, a clean SPI transport driver, native libfprint/fprintd integration, experimental matching, reboot and suspend/resume recovery, and working Omarchy lock-screen authentication.

The baseline is functional, not production-certified.

The work started without a clear Linux implementation plan. The practical path was discovery first, then evidence collection, then a minimal transport driver, then userspace, then matching, and finally desktop integration. That order matters: each layer was proved before the next layer was trusted.

## Core rule

Always separate facts from guesses.

Keep the kernel driver small and hardware-backed. It should transport commands, handle reset/power/IRQ/lifecycle, and expose the device. Do not put biometric matching, synthetic frames, vendor-library emulation, or desktop integration into the kernel.

Preserve every useful Windows/ACPI artifact locally. Public source should contain reproducible code and documentation; proprietary Windows binaries, raw captures, registry dumps, and large research data stay in the local `archive/`.

Never hardcode a developer username or machine-specific home path. Use `$HOME`, `${USER}`, runtime discovery, or an explicit environment variable.

## The workflow

### 1. Identify the hardware

Start on the working Windows installation.

Record:

- Device name and hardware IDs.
- ACPI instance and parent controller.
- Bus type, IRQ, reset/power resources.
- Driver provider, version, INF name, service and package contents.

For this project the important identity was:

- `ACPI\VEN_FTE&DEV_4800`
- `ACPI\FTE4800`
- `\_SB.PC00.SPI2.FPNT`
- FocalTech FTE4800 / FT9368

Do not start coding until the device identity is reproducible.

### 2. Extract the Windows driver safely

Use a read-only Windows collection workflow.

First enumerate the device and its drivers with `pnputil`, then locate the package in the Windows DriverStore. Record the original INF, published `oem*.inf`, DLLs and CAT file. Copy the relevant files into a timestamped research directory and calculate SHA-256 hashes.

Also collect:

- device properties;
- `LogConf`, `BootConfig`, `BasicConfigVector`, and `FilteredConfigVector`;
- registry state;
- PnP resources, stack, services, drivers and interfaces;
- ACPI tables;
- SMBIOS information;
- runtime DLL information and loaded-module evidence.

The archived Windows scripts in `archive/research/windows-package/scripts/` implement this collection. They were designed to collect evidence without installing, removing, resetting, or modifying the Windows driver.

Do not treat a proprietary DLL as an implementation dependency. Use it only as a reference for protocol, resource and algorithm investigation unless its license explicitly permits redistribution.

### 3. Reverse-engineer before guessing

For binaries and firmware:

1. Record hashes and versions.
2. Inspect strings, imports, exports and symbols.
3. Find device IDs, register addresses, SPI transactions, timing constants and status values.
4. Map the call path from the Windows biometric stack into the FocalTech code.
5. Identify image capture, touch detection and enrollment/matching functions.
6. Keep a table of confirmed facts, strong hypotheses and unknowns.

When reverse engineering produces a new fact, add it to `docs/` immediately.

### 4. Decode ACPI and the transport

Inspect the DSDT/SSDT and map the fingerprint device to its SPI controller, chip-select, GPIOs, IRQ and power resources.

Then verify the Linux transport independently:

- reset sequence;
- wake/read/write behavior;
- chip identity;
- IRQ/poll behavior;
- exact SPI packet format;
- required delays;
- capture trigger and image readout.

Prefer small one-purpose tools over a large all-in-one experiment.

### 5. Build the kernel driver as a transport layer

Implement in this order:

1. module registration and ACPI match;
2. SPI configuration;
3. reset/power sequencing;
4. basic I/O;
5. identity read;
6. IRQ/lifecycle handling;
7. raw frame transfer;
8. cleanup and suspend/resume recovery.

Test after every layer.

The kernel must use real sensor data. Never add synthetic frames just to satisfy libfprint or a test harness.

### 6. Prove real capture

A capture is not proven merely because bytes changed.

Use three checks:

- idle frames should be stable;
- a real finger should create a large, repeatable signal change;
- the captured geometry and byte count must match the physical sensor.

For FT9368 the validated frame is 64x80, 5120 bytes.

Save representative captures locally and keep the raw protocol trace with the capture procedure.

### 7. Integrate with libfprint separately

Keep the kernel driver and libfprint development trees separate.

For this project:

- kernel project: `focaltech-fte4800-linux-driver`;
- libfprint development tree: `libfprint-upstream`.

Build libfprint from an isolated checkout/branch. Test and install the native build under a separate prefix rather than replacing the distribution library globally.

Then verify the live `fprintd` process is actually loading the intended library.

### 8. Validate the biometric path

Try standard fingerprint matching first.

For this tiny 64x80 sensor, the NBIS/Bozorth3 path did not produce enough useful minutiae to separate the captured fingers. That finding was established experimentally rather than assumed.

The current experimental matcher is therefore a driver-specific image matcher:

raw frame -> local normalization -> validity mask -> rotation/translation search -> overlap-aware normalized correlation -> best score across five enrollment samples.

Keep a Python reference implementation and a matching C implementation. Make the Python version the specification.

Never choose a threshold from a handful of successful demos. Build genuine and impostor datasets, measure FAR/FRR, inspect failure cases, and keep the threshold clearly marked as experimental until the evidence is adequate.

### 9. Integrate desktop authentication last

Only after hardware and matching work:

- fprintd;
- PAM;
- sudo/polkit;
- lock screen;
- suspend/resume;
- password fallback;
- package-update behavior.

Desktop integration must not hide sensor bugs.

For Omarchy, prefer upstream generic fixes. Do not fork the hardware driver into the desktop shell.

### 10. Validate failure modes

Repeat tests after:

- module unload/reload;
- fprintd restart;
- reboot;
- suspend/resume;
- poor fingerprint placement;
- different fingers;
- repeated failed verification;
- unavailable sensor;
- package upgrade.

Record both successful and failed cases. A failure with a clean error is useful evidence; silently masking it is not.

### 11. Use AI as a controlled engineering system

The project used no paid development tools.

The working setup used:

- ChatGPT + the tunnel/desktop connection as the control plane for research, planning, evidence review, debugging and orchestration;
- Claude Desktop for interactive investigation and remote computer work;
- Agy CLI for parallel agent work, including research, kernel engineering, libfprint work and QA;
- ordinary Linux/Windows tooling for building, tracing, disassembly, testing and archival.

The effective pattern is:

1. Give each agent one narrow question.
2. Require commands, evidence and exact file locations.
3. Do not accept an agent conclusion without reproducing the key observation.
4. Keep one source of truth for the current protocol and architecture.
5. Commit working changes in small logical steps.
6. Run tests after each major change.
7. Archive dead ends instead of deleting useful evidence.
8. Do not let an agent silently replace working system packages or introduce synthetic behavior.
9. Review the final diff for accidental paths, credentials, proprietary files and generated artifacts.

For future driver projects, use multiple agents for parallel investigation, but keep hardware writes and system-wide changes centrally controlled.

## The actual investigation pattern

The project used two parallel tracks: an evidence track and an implementation track.

The evidence track answered “what does the hardware actually do?” using Windows PnP/DriverStore data, ACPI tables, registry/resource blobs, DLL/INF inspection, disassembly, SPI traces, real captures, and archived failed experiments.

The implementation track converted only verified facts into small Linux components. This prevented guesses from becoming driver behavior.

A useful loop for future drivers is:

`observe -> record -> reproduce -> implement -> test -> document -> commit`

When stuck, stop changing the driver and collect another fact. When an experiment fails, keep the failure and write down what it ruled out.

## Main tools and repeated scripts

The core Linux tools used repeatedly were `make`, DKMS, `modprobe`, `dmesg`/`journalctl`, `spi`, `udev`, `fprintd`, `systemctl`, `readelf`, `strings`, `objdump`, Python, shell scripts, Git, and normal `/sys` and `/proc` inspection.

The most useful project scripts became the reusable toolbox:

- `install/install.sh` — prerequisites, DKMS installation, and basic validation.
- `install/build-libfprint.sh` — build the isolated native libfprint tree.
- `install/install-native-fte4800.sh` — install the native libfprint build without replacing the distro library.
- `install/verify-fprintd-runtime.sh` — prove which libfprint the running fprintd process actually loads.
- `install/restore-fprintd-packages.sh` — recover the distribution fprintd/libfprint stack after package changes.
- `install/omarchy-hw-fingerprint-fte4800` — detect ACPI/SPI FTE4800 hardware alongside USB readers.
- `install/omarchy-setup-security-fingerprint-fte4800` — safe setup wrapper that preserves the native stack.
- `tools/ft9368.py` — low-level FT9368 protocol operations used during hardware experiments.
- `tools/fte4800_capture.py` — reproducible real-frame capture.
- `tools/fte4800_selftest.py` — reset/identity/transport checks.
- `tools/live-finger-monitor.py` — observe live physical frame changes.
- `tools/matcher_ref.py` — Python specification for the experimental matcher.
- `tools/matcher_lab.py` and `tools/offline-biometric-eval.py` — offline matcher/evaluation work.
- `tools/native-live-test.c` / `tools/live-native-test.sh` — live native libfprint validation.
- `tools/diagnose_libfprint.py` — userspace diagnosis.
- `tools/collect2.py` — guided genuine/impostor capture collection.

Windows evidence collection was kept separately under `archive/research/windows-package/scripts/`, including the final evidence-gate and resource-extraction scripts. The important Windows sequence was: boot Windows, identify the exact ACPI device, locate its DriverStore package, collect INF/DLL/CAT/package hashes, inspect PnP resources and registry state, extract ACPI/SMBIOS evidence, and copy the useful evidence into the timestamped research archive before returning to Linux.

## AI-assisted strategy

AI was used as an engineering force multiplier, not as an authority.

The practical split was:

- ChatGPT: control plane, architecture decisions, evidence synthesis, command planning, review, and cross-agent coordination through the tunnel/desktop connection.
- Agy CLI: parallel specialist work and agent swarms for research, kernel engineering, libfprint, tooling, QA, and documentation.
- Claude Desktop: interactive investigation and remote-computer work.
- Screenpipe: useful in principle for reconstructing what was on screen, active windows, and work context. A check on 2026-10-03 found no retained captures for the October 1–3 project window; the last retained frame was September 29, so this document does not use Screenpipe as evidence for the project timeline.

For future projects, give agents narrow jobs, require exact evidence, keep a shared fact ledger, and make the control plane approve destructive or system-wide changes. Do not let several agents independently invent competing protocol interpretations.

## Reusable driver-development checklist

For another Linux hardware driver, start with identity and topology, then obtain the working vendor environment, collect a complete evidence bundle, map resources and lifecycle, reproduce raw I/O in small tools, build the smallest possible kernel transport, prove real hardware data, integrate the proper userspace subsystem, test normal and failure paths, package it reproducibly, and only then integrate desktop-specific behavior.

For a sensor with a vendor algorithm, treat the vendor implementation as evidence. First establish whether the upstream algorithm works. If it does not, document why with measurements and keep the replacement matcher isolated, deterministic, auditable, and clearly marked as experimental.

### 12. Keep the repository portable

Before every public commit:

- search for personal usernames and absolute home paths;
- search for secrets and tokens;
- confirm proprietary binaries are not tracked;
- confirm build output is ignored;
- run shell syntax checks;
- run unit tests;
- build the kernel module;
- test the install/check path;
- run `git diff --check`.

Use `$HOME`, `$USER`, or environment variables in examples. Use repository-relative paths in scripts. Never encode the developer account name into code, docs, tests, examples, or service helpers.

## What not to repeat

Do not return to:

- synthetic fingerprint frames;
- kernel-side vendor matcher emulation;
- undocumented shadow-register tricks;
- lowering the matcher threshold just to improve demo success;
- replacing the system libfprint package during experiments;
- hardcoded developer paths;
- deleting raw reverse-engineering evidence because it looks old.

## Current baseline

The 2026-10-03 baseline proves:

- real FT9368 hardware access;
- verified reset and identity protocol;
- real 64x80 image capture;
- five-frame enrollment;
- native libfprint/fprintd operation;
- same-finger matching and different-finger rejection in the current small evaluation set;
- module reload, reboot and suspend/resume recovery;
- working Omarchy lock authentication.

It does not prove production biometric security. The main technical gap is larger, controlled biometric validation and improved placement robustness.

For the current architecture and matcher details, see `docs/matching.md` and `docs/omarchy-integration.md`.
