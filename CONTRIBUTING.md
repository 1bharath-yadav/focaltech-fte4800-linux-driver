# Contributing

Contributions to the FTE4800 / FT9368 Linux driver are welcome.

## Scope

The repository contains:

    Linux SPI transport
    native FTE4800 libfprint integration
    native FocalTech vendor-engine bridge
    Arch packaging
    diagnostics and tests
    hardware and reverse-engineering documentation

Keep the kernel transport hardware-backed and keep biometric processing in userspace.

## Packaging

The production package is:

    packaging/arch/PKGBUILD

It combines:

    upstream libfprint release
        +
    FTE4800 downstream patch
        +
    focal_spi DKMS
        +
    vendor engine runtime
        +
    udev and systemd integration

Stock Arch fprintd is used.

## libfprint updates

Maintain the FTE4800 patch against a current upstream release.

When upstream changes:

    1. select the new upstream release;
    2. rebase or regenerate the FTE4800 patch;
    3. preserve MISC-backed SPI discovery;
    4. build;
    5. run tests;
    6. perform live hardware validation.

Do not permanently pin the package to an obsolete downstream development commit just to avoid rebasing.

## fprintd

Do not patch or rebuild fprintd for normal installation.

The old fprintd preflight patch is historical research and not production.

## Tests

    tests/run-tests.sh
    git diff --check
    bash -n install/*.sh
    bash -n tests/run-tests.sh
    cd packaging/arch
    makepkg -Cfs

Inspect the package contents before installation.

## Proprietary material

Do not add to public changes:

    vendor DLLs
    Windows driver packages
    raw ACPI dumps
    biometric captures
    credentials
    internal agent material

Keep local-only artifacts under archive/.

## Security

The native FocalTech engine is a functional and algorithmic advantage, not a security certification.

See SECURITY.md.
