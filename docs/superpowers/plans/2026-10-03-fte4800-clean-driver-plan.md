# FTE4800 Clean Hardware Driver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Replace the experimental FTE4800 kernel driver with a minimal hardware-backed ACPI/SPI driver using the verified FT9368 protocol.

**Architecture:** Keep one SPI client driver and one narrow compatibility character interface. Native hardware transactions are isolated in protocol helpers; userspace framing is translated without fake registers, fake images, or synthetic state.

**Tech Stack:** Linux kernel SPI/ACPI/GPIO/IRQ APIs, miscdevice, C, pytest/static source tests, DKMS.

**Spec:** docs/superpowers/specs/2026-10-03-fte4800-clean-driver-design.md

## Global Constraints

- FTE4800 uses ACPI-provided SPI mode 0, 8-bit words, active-low CS, 1 MHz.
- Native image capture is a single full-duplex 0x90 0x80 transfer with seven-byte header and 5120-byte payload.
- The hardware image is 64x80 8-bit grayscale; compatibility output is 10240 bytes of big-endian (pixel << 4) words.
- FPNT supplies SPI, reset GPIO, and edge-active-high IRQ; INT3472 camera PMIC resources are unrelated.
- No synthetic frame generation, fake chip IDs, fabricated status, or system-wide libfprint binary patching is part of the driver.
- Preserve Windows research and reverse-engineering evidence until end-to-end hardware validation is complete.

## Review Focus

- Native capture must hold one CS transaction and place payload after the seven-byte header.
- Removing synthetic paths must not remove the real 0x90/0x80 capture path.
- Unbind/remove must not leave userspace with a dangling fp_data.
- IRQ handling must match ACPI edge semantics and must not create an event storm.
- Build/install must keep project source and DKMS source synchronized.

## Task 1: Source-contract tests and baseline

**Files:**
- Create: tests/test_driver_contract.py
- Create: tests/run-tests.sh

**Interfaces:**
- Produces source-contract checks that later cleanup must satisfy.

- [ ] Step 1: Write failing tests that assert the active driver contains no synthetic-frame symbols, no direct libfprint patch offsets, and contains the native capture signature.
- [ ] Step 2: Run python3 -m unittest tests/test_driver_contract.py -v.
Expected: FAIL because current focal_spi.c still contains synthetic-frame code.
- [ ] Step 3: Add the test runner so tests/run-tests.sh executes the contract suite from the repository root.
- [ ] Step 4: Commit the tests with message: test: add FTE4800 driver source contract.

## Task 2: Replace the experimental protocol/state layer

**Files:**
- Modify: focal_spi.c
- Modify: Makefile
- Create: protocol/fte4800_protocol.h
- Create: tests/test_protocol_constants.py

**Interfaces:**
- Produces named protocol constants in protocol/fte4800_protocol.h; native capture helpers remain private implementation details of focal_spi.c.
- Native capture must read exactly 5120 bytes from register 0x90 with flag 0x80.

- [ ] Step 1: Write failing protocol-constant tests for 64x80, 5120-byte native payload, 10240-byte compatibility frame, and seven-byte header.
- [ ] Step 2: Run the protocol test.
Expected: FAIL because the new protocol contract/header does not exist.
- [ ] Step 3: Create protocol/fte4800_protocol.h with named constants only; no behavior.
- [ ] Step 4: Remove fp_sqrt, stage_shifts, generate_synthetic_frame, full_frame_buf references, fake register values, fake chip-ID mapping, and fake touch-trigger state from focal_spi.c.
- [ ] Step 5: Implement native SPI helpers with one spi_sync() full-duplex message for 0x90 0x80 capture and big-endian 16-bit conversion (pixel << 4).
- [ ] Step 6: Keep only real hardware-derived state transitions: reset, IRQ event, frame capture lifecycle, scan acknowledgement, and bounded vendor command translation.
- [ ] Step 7: Run python3 -m unittest tests/test_driver_contract.py tests/test_protocol_constants.py -v.
Expected: PASS.
- [ ] Step 8: Run make W=1.
Expected: kernel module builds with no unused-function or format warnings.
- [ ] Step 9: Commit with message: refactor: make FTE4800 protocol hardware-backed.

## Task 3: Harden lifecycle, userspace boundary, and IRQ

**Files:**
- Modify: focal_spi.c
- Create: tests/test_driver_lifecycle.py

**Interfaces:**
- spidev_read, spidev_write, and ioctl paths return -ENODEV after remove.
- focal_poll uses poll_wait without blocking inside the poll callback.
- IRQ uses rising-edge semantics from ACPI.

- [ ] Step 1: Write failing lifecycle source tests for remove ordering, poll_wait, IRQ trigger mode, and input bounds.
- [ ] Step 2: Run the lifecycle test.
Expected: FAIL on any remaining legacy pattern.
- [ ] Step 3: Implement the minimal lifecycle fixes under the existing ff_lock.
- [ ] Step 4: Validate invalid userspace lengths, ioctl state, and remove ordering in the source-contract tests.
Expected: PASS.
- [ ] Step 5: Run make W=1.
Expected: PASS with no new warnings.
- [ ] Step 6: Commit with message: fix: harden FTE4800 driver lifecycle.

## Task 4: Hardware validation without system-wide binary hacks

**Files:**
- Create: tools/fte4800-selftest.py
- Create: tools/fte4800-capture.py
- Modify: README.md

**Interfaces:**
- Self-test opens /dev/focal_moh_spi, reads native-compatible identity and image data, and validates exact lengths/statistics.
- Capture tool writes a raw frame and optional PGM output for inspection.

- [x] Step 1: Write failing tool tests against mocked binary buffers for length and unpacking rules.
- [x] Step 2: Run them and confirm RED.
- [x] Step 3: Implement the userspace diagnostics using only documented driver commands.
- [x] Step 4: Build and install the DKMS module from the clean worktree.
Expected: loaded module source matches project source hash.
- [x] Step 5: Validate hardware reset, FT9368 identity, IRQ, and one complete 64x80 frame.
Expected: chip ID 0x9368; frame length 5120 native bytes; compatibility buffer length 10240; nonzero image variance.
- [x] Step 6: Commit with message: test: add FTE4800 hardware self-tests.

## Task 5: Repository simplification and final verification

**Files:**
- Modify: .gitignore
- Modify: README.md
- Delete: generated build artifacts and obsolete experiment files only after validation.
- Preserve: FTE4800-Linux-Driver-Research, DSDT.dsl, SSDT*.dsl, extracted-windows-fw, reverse-engineering reports, and known-good backups.

- [x] Step 1: Generate a candidate cleanup list by file age, duplicate hash, and references from active code/docs.
- [x] Step 2: Write a failing cleanup test that detects binaries/objects and obsolete synthetic implementation files still referenced by the active project.
- [x] Step 3: Remove only artifacts proven redundant; do not delete research evidence.
- [x] Step 4: Run the complete suite and make W=1.
Expected: all tests PASS and module builds cleanly.
- [x] Step 5: Run final source scans for synthetic paths, libfprint patch offsets, and fake register values.
Expected: zero matches in active driver/tools.
- [x] Step 6: Commit with message: chore: remove obsolete FTE4800 artifacts.

## Security-sensitive validation boundary

The system-wide /usr/lib/libfprint-2.so.2.0.0 binary is currently patched. This plan does not overwrite it during driver cleanup. The original backup remains /usr/lib/libfprint-2.so.2.0.0.orig; restoring or replacing a system library is a separate reversible system-level action after the clean kernel path is verified.

## Completion criteria

The task is complete only when the clean driver builds, binds to spi-FTE4800:00, reads the physical FT9368 identity, captures a genuine 64x80 frame, survives unbind/rebind without crashes, and has no active synthetic-frame or binary-patch implementation.
