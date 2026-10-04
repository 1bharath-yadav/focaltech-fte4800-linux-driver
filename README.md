# FocalTech FTE4800 / FT9368 Linux Driver

Complete Linux support for the FocalTech FTE4800 / FT9368 SPI fingerprint reader in the Infinix ZERO BOOK 13.

## Current state

The project now has one complete downstream Arch package:

    focaltech-fte4800

A successful package build has been verified as:

    focaltech-fte4800-1.0.3-2-x86_64.pkg.tar.zst

The package contains the full FTE4800 stack:

    focal_spi DKMS kernel transport
    native FTE4800 libfprint driver
    vendor-engine PE/WinBio bridge
    FocalTech vendor biometric DLL
    FTE4800 udev rule
    fprintd systemd drop-in

The system uses the normal Arch fprintd package. fprintd is not patched or rebuilt.

The current package builds upstream libfprint v1.94.10 and then applies the FTE4800 downstream patch. Future upstream updates must follow the same model.

## Architecture

    FTE4800 / FT9368
            |
            v
    focal_spi DKMS
            |
            v
    /dev/focal_moh_spi
            |
            v
    native FTE4800 libfprint
            |
            +---- vendor-engine.c
            |          |
            |          v
            |    FocalTech WinBio engine DLL
            |
            v
        stock fprintd
            |
            v
        pam_fprintd
            |
            +---- SDDM
            +---- sudo / polkit
            +---- Omarchy lock screen

The kernel driver is transport only. It does not perform biometric matching and does not fabricate frames.

## Native FocalTech algorithm

The production verification path uses FocalTech's native WinBio engine through the native Linux PE and WinBio bridge.

Observed vendor-engine processing includes Gaussian and DoG pyramids, scale-space extrema, feature scales and orientations, descriptors, RANSAC, overlap checks and vendor template verification. The exact implementation remains proprietary.

The former experimental NCC and raw-frame matcher is not part of the production path.

The vendor template is stored opaquely:

    FTV1
    uint32 little-endian template size
    opaque FocalTech template

## What using the Windows engine means

Using FocalTech's own engine is a significant improvement over the former experimental matcher because Linux uses the vendor's intended biometric enrollment and verification implementation instead of an independently designed replacement.

It does not prove that the system is 100 percent secure or 100 percent efficient.

Security still depends on the complete chain: sensor, kernel transport, libfprint, native PE and WinBio bridge, proprietary DLL, fprintd, PAM, templates and the desktop session. The proprietary DLL is not independently auditable, and the project does not have production-scale biometric FAR and FRR measurements or a security certification.

Correct claim:

    The active Linux driver uses FocalTech's native biometric engine and has been validated end-to-end on the target hardware.

Do not turn that into a claim of zero FAR, zero FRR or security certification.

## Hardware

    ACPI FTE4800:00
    ACPI device FTE4800
    controller path _SB.PC00.SPI2.FPNT
    sensor FocalTech FT9368
    image 64x80
    pixels 8-bit grayscale
    Linux node /dev/focal_moh_spi

## Capture protocol

Reset:

    HIGH -> LOW for about 10 ms -> HIGH -> wait about 350 ms

Identity request:

    91 80 00 20 00 00 00

Validated identity:

    chip 0x9368
    firmware date 2022-07-29
    geometry 64x80

Capture:

    trigger 70 07 F8 00 3B 00 00 00 01 00 00
    wait about 60 ms
    read 90 80 14 00 00 00 00

Frame size is 5120 bytes.

## Complete package installation

The package is the normal installation mechanism.

    cd ~/projects/focaltech-fte4800-linux-driver/packaging/arch
    makepkg -Cfs
    sudo pacman -U ./focaltech-fte4800-*.pkg.tar.zst
    sudo systemctl daemon-reload
    sudo systemctl restart fprintd

Package-owned runtime:

    /usr/src/focaltech-fte4800-1.0.3/
    /usr/lib/focaltech-fte4800/lib/
    /usr/lib/focaltech-fte4800/ftWbioEngineAdapter.dll
    /usr/lib/systemd/system/fprintd.service.d/00-fte4800.conf
    /usr/lib/udev/rules.d/70-focal-spi.rules

The proprietary engine is not stored in Git. packaging/arch/PKGBUILD fetches
the FocalTech Windows driver package from the Microsoft Update Catalog at build
time, extracts ftWbioEngineAdapter.dll, and verifies the pinned SHA-256.

Source package:
- FocalTech Electronics(ShenZhen)Co.,Ltd - Biometric - 2.2.3.79
- Hardware ID: ACPI\\FTE4800
- Update ID: 7afa06b0-6562-4a5e-87e6-4cd4cc9129c5
- CAB SHA-256: fd589acfa49cca3a1fde87190e9f84ebfb62dee7ecd282007a1b4b6bbd0a3faf
- DLL SHA-256: 2af887cb0925a29757b9f217f656a9963246ba7770dcc4c68e689ccc6505f06b

The project does not claim redistribution rights for the proprietary DLL.
Builds therefore obtain it directly from the vendor's published Windows driver
package rather than committing the binary to this repository.

## Updating libfprint

Do not pin to the historical project development commit.

The update model is:

    upstream libfprint release
            |
            v
    FTE4800 downstream patch
            |
            v
    native libfprint build
            |
            v
    focaltech-fte4800 package

Update procedure:

    1. Change _libfprint_version in packaging/arch/PKGBUILD.
    2. Build against the new upstream release.
    3. Rebase or regenerate the FTE4800 patch if needed.
    4. Verify the custom MISC-backed SPI discovery path.
    5. Build and test.
    6. Perform live enrollment and verification.

## fprintd policy

Stock Arch fprintd is used.

The historical fprintd preflight-status patch is not part of the production stack.

Do not rebuild or patch fprintd unless an independently reproduced fprintd defect requires it.

## Removal

    sudo systemctl stop fprintd
    sudo pacman -Rns focaltech-fte4800
    sudo systemctl daemon-reload
    sudo udevadm control --reload-rules
    sudo udevadm trigger

## Development tooling

The production installation path is the Arch package under `packaging/arch/`.
The old manual installers and historical custom fprintd deployment scripts have
been removed from the active tree. Research snapshots remain under `archive/`
for provenance and reference only.

Use the package for installation and the reusable tools/tests for development,
diagnostics, and validation.

## Validation

    python3 -m unittest discover -s tests -v
    sudo python3 tools/fte4800_selftest.py --reset
    fprintd-list "$USER"
    fprintd-enroll
    fprintd-verify
    journalctl -u fprintd -n 100 --no-pager

## Omarchy

Omarchy provides desktop authentication surfaces. It does not own FTE4800 protocol or biometric matching.

See docs/omarchy-integration.md.

## Security

The vendor engine improves algorithmic compatibility and removes the experimental matcher from the production path. It is not a security certification.

See SECURITY.md.

## Support

If this project is useful to you, you can support its development:

<a href="https://buymeacoffee.com/bharath44" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" style="height: 60px !important;width: 217px !important;"></a>
