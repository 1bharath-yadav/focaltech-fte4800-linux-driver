# Omarchy Integration Plan — FTE4800

## Current target

The Infinix ZERO BOOK 13 has a FocalTech FTE4800 / FT9368 fingerprint reader exposed through ACPI/SPI.

Working stack:

FTE4800/FT9368 -> focal_spi kernel transport -> native libfprint -> fprintd -> pam_fprintd -> Omarchy lock/PAM surfaces.

Omarchy does not need to own the hardware driver. Its role is to discover a usable fingerprint stack and connect PAM authentication to its existing authentication surfaces.

## Verified local state

- Omarchy: 4.0.4-1
- fprintd: 1.94.5-2
- libfprint package: 1.94.100-1
- native FTE4800 libfprint: /opt/fte4800/libfprint/lib/libfprint-2.so.2.0.0
- enrolled fingers: right-index-finger, right-middle-finger
- device: /dev/focal_moh_spi
- Omarchy stock detector: fails for this ACPI/SPI reader
- FTE4800-aware detector: passes
- pacman: IgnorePkg = focaltech-spi-dkms
- PAM: sudo, polkit-1 and omarchy-lock-fingerprint configured
- Omarchy lock retry workaround: bounded retries with 1 second interval
## Core experiment results

Hardware capture first proved that a real touch changes the FT9368 output from a flat idle frame to a high-variance 64x80 physical image.

Live genuine verification:

| Condition | Result |
|---|---:|
| centered / normal placement | MATCH, 0.8904 |
| small position offset | MATCH, 0.8380 |
| clockwise rotation | NO-MATCH, 0.2011 |
| upward placement offset | NO-MATCH, 0.4521 |
| lighter / different placement | NO-MATCH, 0.6566 |
| post-module-reload centered | MATCH, 0.8536 |
| post-resume Omarchy lock | MATCH, 0.8788 |

Different-finger rejection:

- right-middle presented against right-index template: NO-MATCH, 0.6141.

These results show a functioning matcher with significant placement sensitivity. The 0.75 threshold remains unchanged.

Lifecycle:

- full reboot: enrolled prints persisted and verification worked;
- focal_spi unload/reload: device recovered and verification worked;
- fprintd restart: device recovered and remained usable, although two attempts scored below threshold;
- suspend/resume: fprintd reported successful resume and subsequently completed an identify;
- post-resume Omarchy lock: fingerprint PAM started and unlocked the session at 0.8788.
## Why the Omarchy change should be upstream

The current Omarchy hardware detector is USB-centric. Current upstream issue #12588 documents the same class of failure for an SPI fingerprint reader that already works through fprintd: the wizard rejects the reader before setup.

The better upstream change is generic:

1. Do not make the setup wizard depend solely on USB heuristics.
2. After fingerprint packages are available, verify actual fprintd device enumeration before attempting enrollment.
3. Avoid blindly replacing a working alternate/TOD/native libfprint implementation.
4. Keep hardware-specific driver work in the appropriate kernel/libfprint project.

A FTE4800-only addition to Omarchy would solve one laptop but leave the underlying detection architecture unchanged.

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
