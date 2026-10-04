# Research

## Current findings

- Infinix ZERO BOOK 13 uses a FocalTech FTE4800 fingerprint reader over ACPI and SPI.
- The sensor controller is FocalTech FT9368.
- Native image geometry is 64x80, 8-bit grayscale.
- focal_spi exposes /dev/focal_moh_spi.
- The native libfprint driver handles FTE4800 capture and lifecycle.
- The production biometric path uses FocalTech's native WinBio engine through a native Linux PE and WinBio bridge.
- The vendor engine runs directly on Linux without Wine.
- The vendor engine owns enrollment, template construction and verification.
- Templates are stored opaquely in the FTV1 format.
- Stock Arch fprintd is sufficient.
- The historical fprintd patch is not part of the production stack.
- The complete stack is packaged as one local Arch package.
- The package selects an upstream libfprint release and applies the downstream FTE4800 patch afterward.
- The proprietary vendor DLL remains local because redistribution terms are not established.

## Algorithm investigation

Static analysis identified a multi-scale feature pipeline involving Gaussian and DoG pyramids, scale-space extrema, feature scale/orientation processing, descriptors, RANSAC, overlap checks and vendor verification.

The exact internal implementation remains proprietary.

## Security interpretation

Using the vendor engine is a major algorithmic compatibility improvement over the old experimental matcher.

It does not establish 100 percent security, 100 percent efficiency, zero FAR, zero FRR or security certification.

The current evidence establishes end-to-end functional integration on the reference hardware.

## References

Linux kernel:
    https://kernel.org/

libfprint:
    https://gitlab.freedesktop.org/libfprint/libfprint

fprintd:
    https://fprint.freedesktop.org/fprintd/

Infinix ZERO BOOK 13:
    https://infinixmobiles.in/pages/zero-book-13-specs

FTEXX00-Ubuntu:
    https://github.com/vobademi/FTEXX00-Ubuntu

Omarchy:
    https://github.com/omacom/omarchy
