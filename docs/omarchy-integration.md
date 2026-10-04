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

## SDDM login-manager integration

Omarchy currently uses SDDM as the display manager. Arch's documented SDDM configuration supports fingerprint-first authentication by placing `auth sufficient pam_fprintd.so` at the top of `/etc/pam.d/sddm`; password authentication remains available when the fingerprint module does not succeed. See the ArchWiki SDDM and Fprint pages for the underlying PAM configuration guidance.

The project helper `install/configure-sddm-fingerprint.sh` makes this change reversibly. It backs up `/etc/pam.d/sddm`, removes active `autologin.conf*` files from `/etc/sddm.conf.d/`, and does not restart SDDM automatically. This matters because the installed machine currently has an `autologin.conf.disabled` file that SDDM is nevertheless parsing as an autologin configuration.

The helper is intentionally separate from Omarchy's package-owned `/usr/share/omarchy/` files. Run it from the project checkout with `./install/configure-sddm-fingerprint.sh --enable` when ready; use `--restore` to recover the latest backed-up SDDM state.

### GNOME Keyring interaction

Fingerprint authentication proves possession of the enrolled biometric but does not populate `PAM_AUTHTOK`. GNOME Keyring therefore cannot automatically unlock a password-protected Login keyring from the fingerprint alone. This is a fundamental PAM/keyring limitation, not an FTE4800-specific failure.

This machine currently has an intentionally passwordless Omarchy `Default_keyring` plus a separate `Login` collection containing application credentials. The safe approach is not to delete or silently weaken that collection: first establish the SDDM fingerprint-login path, then migrate any credentials that need unattended access into the intended passwordless/default collection or retain password login when the protected keyring must be unlocked.

## Lock-screen fingerprint investigation

The installed Omarchy lock implementation uses a Quickshell `PamContext` against `/etc/pam.d/omarchy-lock-fingerprint`, with bounded retry logic. Current Omarchy reports document several separate failure classes around the same path: the lock screen deliberately blanks displays about five seconds after locking, DPMS wake can cause the interface to re-blank or lose focus, and fingerprint attempts can race suspend/resume.

On this machine the fprintd/vendor-engine logs show successful `Match!` results and clean verify completion, so the intermittent blank is not currently attributable to a fingerprint-engine failure. A controlled reproduction is still required to distinguish the normal five-second display blank from a Wayland/output-loss condition before changing the lock plugin.
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
