# libfprint Downstream Integration

## Current model

The package uses a normal upstream libfprint release and applies the project's FTE4800 patch afterward.

Current tested baseline:

    upstream libfprint v1.94.10
    focaltech-fte4800 1.0.3-2

The upstream version is selected by _libfprint_version in packaging/arch/PKGBUILD.

## Patch contents

The downstream patch currently provides:

    fte4800.c
    fte4800.h
    vendor-engine.c
    vendor-engine.h
    driver registration
    SPI and udev dependency registration
    MISC-backed udev discovery
    device-path handoff
    supported-device listing support

The MISC discovery is required because the ZERO BOOK exposes the transport through /dev/focal_moh_spi rather than a standard spidev node.

## Updating upstream

For a new libfprint release:

    1. change _libfprint_version;
    2. build against the clean upstream release;
    3. apply the downstream patch;
    4. rebase/regenerate affected patch hunks;
    5. preserve the complete FTE4800 discovery chain;
    6. build;
    7. run tests;
    8. perform live enrollment and verification.

Do not retain an obsolete downstream commit merely because it makes patch application easy.

## fprintd

The production stack uses stock Arch fprintd.

The FTE4800 package does not rebuild fprintd and does not apply the historical preflight-status patch.

The package only installs a fprintd service drop-in that selects the packaged native libfprint and vendor DLL and grants access to /dev/focal_moh_spi.

## Proprietary boundary

The Linux driver and native compatibility layer are maintained as source.

The FocalTech vendor DLL remains local because its redistribution terms have not been established.

## References

libfprint:
    https://gitlab.freedesktop.org/libfprint/libfprint

libfprint API:
    https://fprint.freedesktop.org/libfprint-dev/

fprintd:
    https://fprint.freedesktop.org/fprintd/
