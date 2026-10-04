# FTE4800 Fingerprint Matching

## Production path

The active FTE4800 driver does not implement a replacement host-side matcher.

Enrollment and verification are delegated to FocalTech's native ftWbioEngineAdapter.dll through libfprint/drivers/vendor-engine.c.

    64x80 FT9368 frame
            |
            v
    vendor-engine.c
            |
            v
    FocalTech WinBio engine
            |
            +-- feature processing
            +-- quality handling
            +-- enrollment
            +-- template construction
            +-- verification
            |
            v
    FTV1 opaque template

Static analysis identified Gaussian/DoG pyramids, scale-space extrema, feature scale/orientation processing, descriptors, RANSAC, overlap checks and vendor verification.

That describes observed behavior. The exact proprietary implementation remains unknown.

## Template

    FTV1
    uint32 little-endian template size
    opaque FocalTech template

The driver does not reinterpret the vendor template as an image or NBIS minutiae record.

## Linux state machine

Linux handles:

    real finger-down detection
    image-quality gate
    vendor-engine acceptance
    enrollment update
    confirmed finger release
    cancellation
    final result reporting

The vendor engine handles biometric feature extraction, template construction and verification.

## Native PE and WinBio bridge

The vendor DLL runs directly on Linux without Wine.

The bridge provides the Windows runtime surface required by the DLL and establishes the per-thread Windows TEB.

StackBase and StackLimit are refreshed from the active Linux pthread because the vendor CRT can enter __chkstk.

## Validation

Offline replay of real FTE4800 captures demonstrated vendor-engine initialization, enrollment-sample acceptance, template creation and same-finger verification.

Live validation demonstrated fresh multi-sample enrollment, FTV1 persistence and subsequent successful fprintd verification on the physical ZERO BOOK 13.

These establish end-to-end functional integration.

They do not establish production FAR/FRR or security certification.

## Security and efficiency interpretation

Using the native FocalTech engine is preferable to the old experimental matcher because it preserves vendor enrollment and verification behavior.

It does not prove 100 percent security or 100 percent efficiency.

The DLL is proprietary and not independently auditable. The compatibility layer adds security-sensitive native code. The biometric evaluation dataset is not large enough for production characterization.

Correct statement:

    The production path uses FocalTech's native biometric engine and has been validated end-to-end on the target hardware.

## Historical matcher

The former matcher tooling remains research-only:

    tools/matcher_ref.py
    tools/matcher_lab.py
    tools/offline-biometric-eval.py
