# Omarchy Integration Plan — FTE4800

## Current target

The validated reference platform is the Infinix ZERO BOOK 13, whose FocalTech FTE4800 / FT9368 fingerprint reader is exposed through ACPI/SPI. The project is named for the supported FocalTech hardware, not the laptop model.

Working stack:

FTE4800/FT9368 -> focal_spi kernel transport -> native libfprint -> fprintd -> pam_fprintd -> Omarchy lock/PAM surfaces.

Omarchy does not need to own the hardware driver. Its role is to discover a usable fingerprint stack and connect PAM authentication to its existing authentication surfaces.

## Verified local state

The validated local deployment uses the exact FocalTech `ftWbioEngineAdapter.dll` through the native Linux PE/WinBio bridge.

- native FTE4800 libfprint: `/opt/fte4800/libfprint/lib/libfprint-2.so.2.0.0`
- vendor runtime: `/usr/local/lib/fte4800/ftWbioEngineAdapter.dll`
- sensor: `/dev/focal_moh_spi`
- libfprint driver: `fte4800`
- image geometry: 64x80, 8-bit grayscale
- template format: `FTV1` opaque FocalTech vendor template
- enrollment stages: 12

The native deployment has been exercised end-to-end on the physical ZERO BOOK 13: a fresh 12-sample `fprintd-enroll` completed, the resulting template was persisted by fprintd, and `fprintd-verify` subsequently completed successfully.

The Linux bridge refreshes the Windows TEB stack bounds from the current libfprint worker thread before vendor-engine calls. This is required by the vendor CRT stack-probing path.

The previous NCC/raw-frame matcher and its score threshold are historical research only. They are not part of the current production path.

Lifecycle tests already performed during development include fprintd restart and device/module recovery. Additional suspend/resume and lock-screen regression testing should remain part of future packaging validation.
## Why the Omarchy change should be upstream

The current Omarchy hardware detector is USB-centric. Current upstream issue #12588 documents the same class of failure for an SPI fingerprint reader that already works through fprintd: the wizard rejects the reader before setup.

The better upstream change is generic:

1. Do not make the setup wizard depend solely on USB heuristics.
2. After fingerprint packages are available, verify actual fprintd device enumeration before attempting enrollment.
3. Avoid blindly replacing a working alternate/TOD/native libfprint implementation.
4. Keep hardware-specific driver work in the appropriate kernel/libfprint project.

A FTE4800-only addition to Omarchy would solve one laptop but leave the underlying detection architecture unchanged.

## Stock setup package behavior

The current Omarchy fingerprint setup script installs `libfprint-git` when the fingerprint stack is considered missing. That package conflicts with the dedicated native FTE4800 deployment and can replace the distro userspace library selected by fprintd.

For this target, the FTE4800-aware project wrapper installs only the authentication daemon dependencies it needs and keeps `/opt/fte4800` as the fprintd runtime. The wrapper is a local integration workaround; the long-term fix belongs in Omarchy's package-selection and hardware-detection flow.

## Lock-screen upstream opportunity

Omarchy's lock screen uses the dedicated omarchy-lock-fingerprint PAM service. Current upstream reports document related robustness problems:

- fingerprint PAM can be restarted every 250 ms without a bound or backoff;
- a transient fprintd probe failure can disable fingerprint for the rest of the lock session;
- the first fingerprint attempt after resume can race suspend/lock handling.

Our local results add another data point: the FTE4800 stack can produce sub-threshold scores from changed placement, so retry behavior must preserve password fallback and avoid turning every failure into a rapid PAM restart.

Candidate upstream pieces:

- bounded or backoff-based fingerprint retries;
- no rapid restart after device/service errors;
- re-check availability after transient fprintd failures;
- preserve password authentication when fingerprint is unavailable;
- optionally surface fingerprint PAM messages in the lock UI.

## Plugin assessment

A third-party Omarchy plugin is useful for UI or convenience tooling, but it is not the right owner for PAM authentication.

The current plugin contract scopes third-party plugins away from authentication services. Authentication capabilities are reserved for trusted first-party code, and the shell's authentication services are kept outside the ordinary third-party object graph.

A plugin can be useful for:

- fingerprint status;
- setup/status UI;
- diagnostics;
- launching a user-owned helper that reports fprintd state.

It should not own PAM policy, fprintd authorization, or lock-screen authentication.

## Proposed contribution sequence

### PR 1 — generic fingerprint detection

Scope only setup/detection.

Goal: allow Omarchy to proceed when a fingerprint reader is reachable through a non-USB bus or when fprintd reports a usable device.

Do not include FTE4800 driver code.

### PR 2 — fingerprint authentication robustness

Scope the lock-screen fingerprint flow.

Goal: bounded/backoff retry, resilient transient errors, preserved password fallback, and better suspend/resume handling.

This aligns with existing Omarchy fingerprint lock issues.

### Optional plugin

Keep a separate plugin only for user-facing fingerprint status/setup UX. Do not make it a security-critical dependency.

## Local workaround status

The project contains an FTE4800-aware detector/setup wrapper and a root installer for this laptop. Those are temporary integration workarounds and test fixtures.

The Omarchy package-managed files under /usr/share/omarchy should eventually remain unmodified on a normal installation once upstream changes land.

## Security constraints

- Do not lower the FTE4800 matcher threshold merely to compensate for poor placement.
- Keep password fallback available.
- Do not modify system-auth globally for the fingerprint reader.
- Do not treat the current two-finger dataset as biometric security certification.
- Keep the FTE4800 kernel and libfprint implementation outside Omarchy.
